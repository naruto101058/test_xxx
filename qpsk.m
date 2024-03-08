% 信号参数
Fs = 5000;          % 采样率
T = 1/Fs;           % 采样间隔
L = 100;           % 信号长度
t = (0:5000-1)*T;       % 时间向量
M = 100;
% 生成随机用户比特序列
user_bits = randi([0, 1], 1, L);
disp('随机序列的前10位为：');
user_bits(1:10)
% 串并变换分成 I 路和 Q 路
i_channel = user_bits(1:2:end);
disp('I路序列前5位为：');
i_channel(1:5)
q_channel = user_bits(2:2:end);
disp('Q路序列前5位为：')
q_channel(1:5)
% Kaiser 窗参数
beta = 5;           % 参数 beta 控制窗口的形状，可以调整以满足缓升缓降的需求
% 生成 Kaiser 窗
kaiser_window = kaiser(L, beta);
%kaiser_window = rectwin(L);
%I路
if i_channel(1,1) == 1
    a = kaiser_window;
end
if i_channel(1,1) == 0
    a = -kaiser_window;
end
for i = 2:length(i_channel)
    if i_channel(1,i) == 1
        a = vertcat(a,kaiser_window);
    end
    if i_channel(1,i) == 0
        a = vertcat(a,-kaiser_window);
    end
end
a=a';
f = 100;% 载波频率
i_cos =a.*cos(2*pi*f*t);%I(t)cos(wct)

%Q路

if q_channel(1,1) == 1
    b = kaiser_window;
end
if q_channel(1,1) == 0
    b = -kaiser_window;
end
for i = 2:length(q_channel)
    if q_channel(1,i) == 1
        b = vertcat(b,kaiser_window);
    end
    if q_channel(1,i) == 0
        b = vertcat(b,-kaiser_window);
    end
end
b=b';
q_sin =-b.*sin(2*pi*f*t);%   -Q(t)sin(wct)
s_qpsk  = i_cos + q_sin;


%I(t)的频域图像
N = length(a);  % 信号长度
frequencies1 = Fs * (0:(N/2))/N;  % 计算对应频率
fft_result = fft(a);
% 仅保留正频率部分
fft_result_positive = fft_result(1:N/2+1);

% 计算频谱的幅度
amplitude_spectrum1 = abs(fft_result_positive);





%qpsk的频域图像
N = length(s_qpsk);  % 信号长度
frequencies2 = Fs * (0:(N/2))/N;  % 计算对应频率
fft_result = fft(s_qpsk);
% 仅保留正频率部分
fft_result_positive = fft_result(1:N/2+1);

% 计算频谱的幅度
amplitude_spectrum2 = abs(fft_result_positive);




%低通滤波器，方式一
% 设置实际频率和采样率
actual_cutoff_frequency = 50;  % 实际截止频率
% 计算归一化频率
normalized_cutoff_frequency = actual_cutoff_frequency / (Fs/2);
filter_order = 40;      % 滤波器阶数 选择30-100     40时延不大
% 设计低通 FIR 滤波器
lp_filter = designfilt('lowpassfir', 'FilterOrder', filter_order, 'CutoffFrequency', normalized_cutoff_frequency);


sqpsk_i = s_qpsk.*cos(2*pi*f*t);   %不注销
filtered_signal1 = filter(lp_filter, sqpsk_i);



%带通滤波器，方式二
%passband_freq = [10, 50];
%filtered_signal1 = bandpass(sqpsk_i, passband_freq, Fs);


pdst1=1*(filtered_signal1>0);          % 滤波后的向量的每个元素和0进行比较，大于0为1，否则为0
I_judge = [];
% 取码元的中间位置上的值进行判决
for j=L/2:L:(L*M/2)
    if pdst1(j)>0
        I_judge=[I_judge,1];
    else
        I_judge=[I_judge,0];
    end
end
disp('I路解调后的序列前五位：')
I_judge(1:5)





sqpsk_q = -s_qpsk.*sin(2*pi*f*t);
filtered_signal2 = filter(lp_filter, sqpsk_q);
%方式二
%passband_freq = [10, 50];
%filtered_signal2 = bandpass(sqpsk_q, passband_freq, Fs);


pdst2=1*(filtered_signal2>0);          % 滤波后的向量的每个元素和0进行比较，大于0为1，否则为0
Q_judge = [];
% 取码元的中间位置上的值进行判决
for j=L/2:L:(L*M/2)
    if pdst2(j)>0
        Q_judge=[Q_judge,1];
    else
        Q_judge=[Q_judge,0];
    end
end
disp('Q路解调后的序列前五位：')
Q_judge(1:5)

%I,Q路合并
receiver_bits = zeros(1,length(I_judge)+length(Q_judge));
receiver_bits(1:2:end) = I_judge;
receiver_bits(2:2:end) = Q_judge;
disp('接收端收到序列的前10位');
receiver_bits(1:10)


figure;
subplot(2,1,1);
plot(50*t,pdst1,'LineWidth',1.5);
title('经过抽样判决的I路信号')
xlabel('时间(s)')
ylabel('幅度')
subplot(2,1,2);
plot(50*t,pdst2,'LineWidth',1.5);
title('经过抽样判决的Q路信号')
xlabel('时间(s)')
ylabel('幅度')



figure;
subplot(4,1,1);
plot(50*t,sqpsk_i);
title('sqpsk_i(t)');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(4,1,2);
plot(50*t,filtered_signal1);
title('低通滤波之后的I路qpsk');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(4,1,3);
plot(50*t,sqpsk_q);
title('sqpsk_q(t)');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(4,1,4);
plot(50*t,filtered_signal2);
title('低通滤波之后的Q路qpsk');
xlabel('Time (s)');
ylabel('Amplitude');




figure;
subplot(4,1,1);
plot(50*t, a);
title('I(t)');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(4,1,2);
plot(frequencies1, amplitude_spectrum1);
title('I(t)的频域');
xlabel('Frequency (Hz)');
ylabel('Amplitude');


subplot(4,1,3);
plot(50*t, s_qpsk);
title('s_qpsk(t)');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(4,1,4);
plot(frequencies2, amplitude_spectrum2);
title('Frequency Domain Spectrum');
xlabel('Frequency (Hz)');
ylabel('Amplitude');


figure;
subplot(5,1,1);
plot(50*t,a,'LineWidth', 1.5);
title('I路双极性不归零序列');
xlabel('时间（s）');
ylabel('幅度');


subplot(5,1,2);
plot(50*t,i_cos);
title('I(t)cos(wct)');
xlabel('时间（s）');
ylabel('幅度');

subplot(5,1,3);
plot(50*t,b,'LineWidth', 1.5);
title('Q路双极性不归零序列');
xlabel('时间（s）');
ylabel('幅度');

subplot(5,1,4);
plot(50*t,q_sin);
title('-Q(t)sin(wct)');
xlabel('时间（s）');
ylabel('幅度');

subplot(5,1,5);
plot(50*t,s_qpsk);
title('Qpsk调制信号');
xlabel('时间（s）');
ylabel('幅度');
