# Pacman-Flatpak-Auto-Updater
A simple yet robust Bash script that automates weekly system updates for Arch-based Linux systems using pacman and flatpak, with a clean GUI summary using zenity.
🛠 Features:

    Auto-runs on Sundays — ideal for scheduled system maintenance.

    Performs updates via pacman and flatpak silently in the background.

    Displays detailed changelogs for each update in a user-friendly Zenity dialog.

    Smart formatting with package versions and app IDs clearly listed.

This script is ideal for those who want their system kept up-to-date quietly and efficiently, with clean visual feedback — no terminal watching needed. Add it to a cron job or systemd timer or go simple and put it in auto start using KDE, and forget the rest.
Currently it updates on sundays only this is to prevent any problems related to buggy updates in workdays.
