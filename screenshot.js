function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

const puppeteer = require('puppeteer');
const Jimp = require('jimp');

const url = process.argv[2];
const jpgPath = process.argv[3];

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage().catch((err) => { console.log(err); });
  await page.setViewport({width: 1200, height: 900});
  await getScreenshot(page, jpgPath);

  let counter = 0;
  let allOne = true;

  while (allOne && counter < 10) {
    allOne = await isAllOneColor(jpgPath)
    console.log("iterating", counter);
    await getScreenshot(page, jpgPath);
    counter++;
  }

  await browser.close();
})();

async function getScreenshot(page, file) {
  await page.goto(url).catch((err) => { console.log(err); });
  await sleep(1000);
  return await page.screenshot({path: jpgPath}).catch((err) => { console.log("error", err); });
}

const pixelEqual = (first, second) => first.every((el, i) => second[i] === el)

async function isAllOneColor(file) {
  let allSame = true;
  let firstPixel = [];


  await Jimp.read(file).then(image => {
    const result = image.scan(0, 0, image.bitmap.width, image.bitmap.height, function(x, y, idx) {

      var red = this.bitmap.data[idx + 0];
      var green = this.bitmap.data[idx + 1];
      var blue = this.bitmap.data[idx + 2];
      var alpha = this.bitmap.data[idx + 3];

      const currentPixel = [red, green, blue, alpha];

      if (!firstPixel.length) {
        firstPixel = currentPixel;
      } else if (!pixelEqual(firstPixel, currentPixel)) {
        allSame = false;
      }
    });
  });

  return allSame;
}
