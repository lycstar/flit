/// 本机重连策略。电脑激活使用固定 TCP 端口，不依赖无线调试的 mDNS 广播。
/// 这里只记住连接方式，不表示 adbd 仍在运行或系统仍保留授权。
enum AdbConnectionMethod { wireless, usb }

const adbUsbPort = '5555';
