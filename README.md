# Proxmox Inventory Markdown Generator
![image](https://github.com/user-attachments/assets/0fba7539-68fb-4fb1-a0ae-77d89b7cfea0)

Этот Bash-скрипт собирает информацию о хосте Proxmox, виртуальных машинах (VM) и контейнерах (LXC), и сохраняет результат в виде Markdown-таблицы.

## 📦 Возможности

- Сбор IP, MAC, описания, статуса и типа хоста/ВМ/LXC
- Разделение на онлайн и оффлайн таблицы
- Чтение описания (`description`) из конфигурации
- Автоматическое форматирование для Markdown

## 🛠️ Зависимости

Убедитесь, что следующие пакеты установлены:

```bash
sudo apt update
sudo apt install -y jq qemu-guest-agent
```
