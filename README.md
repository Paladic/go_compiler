
# Компилятор языка Go

Учебная реализация компилятора языка программирования **Go 1.27**.

Компилятор разрабатывается в соответствии с официальной спецификацией языка Go версии 1.27.

## Полезные ссылки

- **Reference Manual:** [The Go Programming Language Specification](https://go.dev/ref/spec)
- **Онлайн-компилятор:** [The Go Playground](https://go.dev/play)

---

# Настройка окружения

Для сборки проекта на Windows необходимо установить:

- [WinFlexBison](https://github.com/lexxmark/winflexbison/releases)
- [MSYS2](https://www.msys2.org/)
- [Visual Studio Code](https://code.visualstudio.com/)

---

## 1. Установка Flex

### Скачивание

Скачайте последнюю версию WinFlexBison:

https://github.com/lexxmark/winflexbison/releases

Распакуйте архив в удобную папку.

Например:

```text
D:\programms\WinFlexBison
```

Внутри должны находиться файлы:

```text
win_flex.exe
win_bison.exe
```

### Добавление Flex в PATH

Перейдите в:

```text
Изменение системных переменных среды
→ Переменные среды
→ Системные переменные
→ Path
→ Изменить
→ Создать
```

Добавьте путь к папке с Flex:

```text
D:\programms\WinFlexBison
```

Проверить установку можно командой:

```powershell
win_flex --version
```

---

## 2. Установка GCC

### Установка MSYS2

Скачайте MSYS2:

https://www.msys2.org/

Установите его в удобное место.

Например:

```text
D:\programms\msys2
```

Запустите:

```text
msys2.exe
```

Выполните обновление пакетов:

```bash
pacman -Syu
```

После этого установите GCC:

```bash
pacman -S mingw-w64-ucrt-x86_64-gcc
```

После установки GCC должен находиться в:

```text
D:\programms\msys2\ucrt64\bin
```

В этой папке должен присутствовать файл:

```text
gcc.exe
```

### Добавление GCC в PATH

Перейдите в:

```text
Изменение системных переменных среды
→ Переменные среды
→ Системные переменные
→ Path
→ Изменить
→ Создать
```

Добавьте путь к папке с GCC:

```text
D:\programms\msys2\ucrt64\bin
```

Проверить установку можно командой:

```powershell
gcc --version
```

---

## 3. Настройка Visual Studio Code

После изменения `PATH` полностью перезапустите Visual Studio Code.

Откройте **корневую папку проекта**:

```text
File → Open Folder
```

Рекомендуемые расширения:

- `Bison/Flex Language Support`
- `C/C++`

---

## 4. Сборка проекта

Для сборки проекта используется задача VS Code из файла:

```text
.vscode/tasks.json
```

Для запуска сборки нажмите:

```text
Ctrl + Shift + B
```

При сборке лексера выполняется следующая цепочка:

```text
lexer.l
   ↓
win_flex
   ↓
lex.yy.c
   ↓
gcc
   ↓
lexer.exe
```

---

## 5. Запуск лексера

Для запуска лексера в интерактивном режиме:

```text
Ctrl + Shift + P
→ Tasks: Run Task
→ Run Lexer
```

После этого лексер запустится в терминале и будет ожидать ввод текста.

Например:

```text
foo = 123 + bar;
```

---

## 6. Запуск тестов лексера

Для запуска всех тестов:

```text
Ctrl + Shift + P
→ Tasks: Run Task
→ Test all Lexer
```

Перед запуском тестов лексер автоматически пересобирается.

После этого лексер последовательно запускается для всех файлов:

```text
tests\lexer\*.txt
```

Каждый `.txt`-файл используется как входной текст для лексера.
