// Обрывы сети там, где нет dart:io, — то есть в веб-сборке.
//
// В браузере до сокетов не добраться вовсе: обрыв приезжает от http как
// ClientException, и его ловит общий код. Здесь ловить нечего.
bool isPlatformNetworkError(Object error) => false;
