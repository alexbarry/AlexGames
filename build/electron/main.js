const { app, BrowserWindow } = require('electron/main')

const path = require('path');
const fs = require('fs');

/*
// Create a directory for logs
const logDirectory = path.join(app.getPath('userData'), 'logs');
if (!fs.existsSync(logDirectory)) {
    fs.mkdirSync(logDirectory);
}

// Redirect console.log to a log file
const logPath = path.join(logDirectory, 'electron.log');
const logStream = fs.createWriteStream(logPath, { flags: 'a' });
process.stdout.write = process.stderr.write = logStream.write.bind(logStream);
*/

const createWindow = async function() {
  const win = new BrowserWindow({
    width: 800,
    height: 600
  })

  //debugger;
  //win.webContents.openDevTools();
  win.loadFile('../wasm/out/http_out/index.html');
  //win.loadURL('https://alexbarry.github.io/AlexGames');
  //await new Promise(r => setTimeout(r, 5000));
}

app.whenReady().then(async function () {
  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow()
    }
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})
