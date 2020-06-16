# ARProject
Processing code for CSC.T439: Augmented Reality Final Project

# How to get started

1. Clone repository and copy tasks.json
```
> git clone https://github.com/bana118/ARProject.git
> cd ARProject
> cp .vscode/tasks.json.example .vscode/tasks.json
```

2. Modify .vscode/tasks.json (replace "C:\\processing-3.5.4\\processing-java.exe" to location of your processing-java.exe)

3. Press Ctrl+Shift+B ("Processing Language" VSCode extentions is required)


# Detect tracker
My    towardsList is this one:    final int[] towardsList = {0x1228, 0x690,0x5a,0x272};

When the fourth(0x272,which is the last one of that four marker picutures) comes closely  to other one
