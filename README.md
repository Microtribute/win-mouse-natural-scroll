# Natural Scrolling

This repository contains a PowerShell script that enables the natural scrolling behavior (reverse scrolling) for your connected USB/Bluetooth mice under Windows 7, 8, 10, 11, and more.

## Prerequisite

You must allow the system to run a PowerShell script that is not digitally signed.

```sh
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## Usage

Enable natural scrolling

```sh
.\natural-scrolling.ps1 enable
```

Revert back to default scrolling

```sh
.\natural-scrolling.ps1 disable
```

You must restart your computer for the change to take effect.
