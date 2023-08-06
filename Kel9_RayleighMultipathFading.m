% Inisialisasi
sampleRate1MHz = 1e6; % Sample rate 1 MHz
sampleRate44_1kHz = 44.1e3; % Sample rate 44.1 kHz
c = 3e8; % kecepatan cahaya
Fdoppler = 2e9; % frekuensi doppler

% Input dari pengguna untuk variabel v
v = input('Masukkan kecepatan (m/s): ');

% Input dari pengguna untuk jumlah channel
numChannels = input('Masukkan jumlah channel: ');

% Menggunakan input jumlah channel untuk menginisialisasi gainVector dan delayVector
gainVector = zeros(1, numChannels);
delayVector = zeros(1, numChannels);

for i = 1:numChannels
    gainVector(i) = input(sprintf('Masukkan nilai gain untuk channel ke-%d (dB): ', i));
    delayVector(i) = input(sprintf('Masukkan nilai delay untuk channel ke-%d (s): ', i));
end

maxDopplerShift = (2*v*Fdoppler)/c ;

% Membuat function rayleigh channel
rayChan = comm.RayleighChannel( ...
    'SampleRate', sampleRate1MHz, ...
    'PathDelays', delayVector, ...
    'AveragePathGains', gainVector, ...
    'MaximumDopplerShift', maxDopplerShift, ...
    'RandomStream', 'mt19937ar with seed', ...
    'Seed', 10, ...
    'PathGainsOutputPort', true);

% Modulasi dan filter channel
qamMod = comm.RectangularQAMModulator('ModulationOrder', 16); % Objek modulator 16-QAM
bpskMod = comm.BPSKModulator(); % Objek modulator BPSK

bitsPerFrame = 1000; % Jumlah bit per frame
msg = randi([0 1], bitsPerFrame, 1); % Menghasilkan data acak

% Modulasi data untuk transmisi melalui kanal
modSignalQAM = qamMod(msg);
modSignalBPSK = bpskMod(msg);

% Modulasi data untuk transmisi melalui kanal
modSignalQAM = qamMod(msg);
modSignalBPSK = bpskMod(msg);

% Melakukan kanal Rayleigh pada data termodulasi
rayChan(modSignalQAM);
rayChan(modSignalBPSK);

% Visualisasi Respons Impuls dan Frekuensi Saluran
release(rayChan);

rayChan.Visualization = 'Impulse and frequency responses';
rayChan.SamplesToDisplay = '100%';

numFrames = 2; % Jumlah frame yang akan ditampilkan

for i = 1:numFrames
    % Membuat data acak
    msg = randi([0 1], bitsPerFrame, 1);
    % Modulasi data
    modSignalQAM = qamMod(msg);
    modSignalBPSK = bpskMod(msg);
    % Melewati data melalui kanal dan menampilkan respons kanal
    rayChan(modSignalQAM);
    rayChan(modSignalBPSK);

end

% Visualisasi Spektrum Doppler
release(rayChan);
rayChan.Visualization = 'Doppler spectrum';

numFrames = 5000; % Jumlah frame yang akan ditampilkan

for i = 1:numFrames
    msg = randi([0 1], bitsPerFrame, 1);
    modSignalQAM = qamMod(msg);
    modSignalBPSK = bpskMod(msg);
    rayChan(modSignalQAM);
    rayChan(modSignalBPSK);
end

% Narrowband atau Fading Frekuensi-Flat
release(rayChan);
rayChan.Visualization = 'Impulse and frequency responses';
rayChan.SampleRate = sampleRate44_1kHz;
rayChan.SamplesToDisplay = '100%';

numFrames = 2; % Jumlah frame yang akan ditampilkan

for i = 1:numFrames
    msg = randi([0 1], bitsPerFrame, 1);
    modSignalQAM = qamMod(msg);
    modSignalBPSK = bpskMod(msg);
    rayChan(modSignalQAM);
    rayChan(modSignalBPSK);
end

release(rayChan);
rayChan.PathDelays = 0;
rayChan.AveragePathGains = 0;

for i = 1:numFrames
    msg = randi([0 1], bitsPerFrame, 1);
    modSignalQAM = qamMod(msg);
    modSignalBPSK = bpskMod(msg);
    rayChan(modSignalQAM);
    rayChan(modSignalBPSK);
end

release(rayChan);
rayChan.Visualization = 'Off';

% Konfigurasi Time Scope untuk menampilkan magnitudo path gain
gainScope = timescope( ...
    'SampleRate', rayChan.SampleRate, ...
    'TimeSpanSource', 'Property', ...
    'TimeSpan', bitsPerFrame/2/rayChan.SampleRate, ...
    'Name', 'Multipath Gain', ...
    'ShowGrid', true, ...
    'YLimits', [-40 10], ...
    'YLabel', 'Gain (dB)');

msg = randi([0 1], bitsPerFrame, 1);
modSignalQAM = qamMod(msg);
modSignalBPSK = bpskMod(msg);
[~, rayPathGainQAM] = rayChan(modSignalQAM);
[~, rayPathGainBPSK] = rayChan(modSignalBPSK);

gainScope(10*log10(abs(rayPathGainQAM).^2));

release(rayChan);

rayChan.PathDelays = delayVector;
rayChan.AveragePathGains = gainVector;
rayChan.MaximumDopplerShift = 5;

% Membuat 16-QAM modulator and BPSK modulator
qamMod = comm.RectangularQAMModulator('ModulationOrder', 16, 'BitInput', true);
bpskMod = comm.BPSKModulator();

% Membuat constellation diagram 
constDiagQAM = comm.ConstellationDiagram( ...
    'Name', 'Received Signal After Rayleigh Fading (16-QAM)', ...
    'XLimits', [-4 4], ...
    'YLimits', [-4 4]);

constDiagBPSK = comm.ConstellationDiagram( ...
    'Name', 'Received Signal After Rayleigh Fading (BPSK)', ...
    'XLimits', [-1.5 1.5], ...
    'YLimits', [-1.5 1.5]);
    
   fprintf('\n=======================\n'); 
numFrames = 16;

numErrorsQAM = 0; % Counter for bit errors in 16-QAM
numErrorsBPSK = 0; % Counter for bit errors in BPSK
totalBitsQAM = 0; % Counter for total bits transmitted in 16-QAM
totalBitsBPSK = 0; % Counter for total bits transmitted in BPSK

for n = 1:numFrames
    msg = randi([0 1], bitsPerFrame, 1);
    modSignalQAM = qamMod(msg);
    modSignalBPSK = bpskMod(msg);
    rayChanOutQAM = rayChan(modSignalQAM);
    rayChanOutBPSK = rayChan(modSignalBPSK);
    constDiagQAM(rayChanOutQAM);
    constDiagBPSK(rayChanOutBPSK);
    
    receivedBitsQAM = qamdemod(rayChanOutQAM, 16, 'OutputType', 'bit');
    receivedBitsBPSK = real(rayChanOutBPSK) < 0; 
    
    numErrorsQAM = numErrorsQAM + biterr(msg, receivedBitsQAM);
    numErrorsBPSK = numErrorsBPSK + biterr(msg, receivedBitsBPSK);
    totalBitsQAM = totalBitsQAM + bitsPerFrame;
    totalBitsBPSK = totalBitsBPSK + bitsPerFrame;

    if n == numFrames/2
        berQAM = numErrorsQAM / totalBitsQAM; % BER for 16-QAM
        berBPSK = numErrorsBPSK / totalBitsBPSK; % BER for BPSK
        fprintf('Bit Error Rate (BER) for 16-QAM: %f\n', berQAM);
        fprintf('Bit Error Rate (BER) for BPSK: %f\n', berBPSK);
    end
end