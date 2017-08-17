const spawnSync = require('child_process').spawnSync;
const fs = require('mz/fs');

const webdriver = require('selenium-webdriver'),
      By = webdriver.By,
      until = webdriver.until;

const sleep = (time) => {spawnSync('sleep', [time/1000]);};

async function run() {
    let tmpdir = await fs.mkdtemp(process.env.TMPDIR);

    let chromeCapabilities = webdriver.Capabilities.chrome();
    chromeCapabilities.set('chromeOptions', {
        prefs: {
            download: {
                default_directory: tmpdir,
                prompt_for_download: false
            }
        }
    });

    let driver = new webdriver.Builder()
        .forBrowser('chrome')
        .withCapabilities(chromeCapabilities)
        .build();

    driver.get("https://www.audible.com/sign-in");

    driver.findElement(By.name("email")).sendKeys("");
    driver.findElement(By.name("password")).sendKeys("");

    driver.findElement(By.id("signInSubmit-input")).click();

    driver.wait(until.titleIs('Audible.com'), 3000);

    driver.get("https://www.audible.com/lib");

    let newest = driver.findElement(By.css(".adbl-download-it"));
    newest.click();

    let items : string[] = [];
    do {
        items = await fs.readdir(tmpdir);
        sleep(1500);
    } while(!(items.length == 1 && !!items[0].match('\.aax$')));

    await fs.rename(tmpdir + "/" + items[0], process.cwd() + "/" + items[0]);

    console.log(items[0]);

    driver.quit();
}

run();
