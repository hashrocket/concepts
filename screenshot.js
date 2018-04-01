function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

const puppeteer = require('puppeteer');

const url = process.argv[2];
const jpgPath = process.argv[3];

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage().catch((err) => { console.log(err); });
  await page.setViewport({width: 1200, height: 900});
  await page.goto(url).catch((err) => { console.log(err); });
  await sleep(1000);
  await page.screenshot({path: jpgPath}).catch((err) => { console.log(err); });
  await browser.close();
})();
