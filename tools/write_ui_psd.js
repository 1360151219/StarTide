#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const sharp = require("sharp");
const { writePsdBuffer } = require("ag-psd");

const root = path.resolve(__dirname, "..");
const manifestPath = process.argv[2];
const outputPath = process.argv[3];

if (!manifestPath || !outputPath) {
  throw new Error("usage: write_ui_psd.js <manifest.json> <output.psd>");
}

async function imageDataFor(relativePath) {
  const absolutePath = path.resolve(root, relativePath);
  const { data, info } = await sharp(absolutePath)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  return {
    width: info.width,
    height: info.height,
    data: new Uint8ClampedArray(data.buffer, data.byteOffset, data.byteLength),
  };
}

function textDescriptor(layer, placement) {
  if (!layer.text) {
    return undefined;
  }
  const text = layer.text;
  return {
    text: text.value,
    transform: [
      1,
      0,
      0,
      1,
      placement.left + text.transformX,
      placement.top + text.transformY,
    ],
    style: {
      font: { name: text.font },
      fontSize: text.fontSize,
      fillColor: text.fillColor,
    },
    paragraphStyle: {
      justification: text.justification,
    },
  };
}

async function buildLayer(layer, placement) {
  const imageData = await imageDataFor(layer.path);
  const result = {
    name: layer.name,
    left: placement.left + layer.left,
    top: placement.top + layer.top,
    imageData,
    hidden: Boolean(layer.hidden),
  };
  const text = textDescriptor(layer, placement);
  if (text) {
    result.text = text;
  }
  return result;
}

async function buildScreenGroup(screen, placement) {
  const categories = new Map();
  for (const layer of screen.layers) {
    if (!categories.has(layer.category)) {
      categories.set(layer.category, []);
    }
    categories.get(layer.category).push(layer);
  }
  const categoryNames = [...categories.keys()].sort().reverse();
  const children = [];
  for (const category of categoryNames) {
    const layers = categories.get(category);
    const categoryChildren = [];
    for (const layer of [...layers].reverse()) {
      categoryChildren.push(await buildLayer(layer, placement));
    }
    children.push({
      name: category,
      opened: false,
      children: categoryChildren,
    });
  }
  return {
    name: `画板 ${screen.id} · ${screen.title}`,
    opened: false,
    children,
    artboard: {
      rect: {
        top: placement.top,
        left: placement.left,
        bottom: placement.top + screen.height,
        right: placement.left + screen.width,
      },
      presetName: "Star Tide Mobile 540×960",
      color: { r: 6, g: 23, b: 34 },
      backgroundType: 1,
    },
  };
}

async function main() {
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  const composite = await imageDataFor(manifest.compositePath);
  const placementByScreen = new Map(manifest.placements.map((item) => [item.screenId, item]));
  const screenGroups = [];
  for (const screen of manifest.screens) {
    const placement = placementByScreen.get(screen.id);
    screenGroups.push(await buildScreenGroup(screen, placement));
  }
  const psd = {
    width: manifest.width,
    height: manifest.height,
    imageData: composite,
    children: [...screenGroups].reverse(),
    artboards: {
      count: screenGroups.length,
      autoExpandEnabled: true,
      autoNestEnabled: false,
      autoPositionEnabled: false,
      shrinkwrapOnSaveEnabled: false,
      docDefaultNewArtboardBackgroundColor: { r: 6, g: 23, b: 34 },
      docDefaultNewArtboardBackgroundType: 1,
    },
    imageResources: {
      resolutionInfo: {
        horizontalResolution: 72,
        horizontalResolutionUnit: "PPI",
        widthUnit: "Pixels",
        verticalResolution: 72,
        verticalResolutionUnit: "PPI",
        heightUnit: "Pixels",
      },
      versionInfo: {
        hasRealMergedData: true,
        writerName: "Codex + ag-psd",
        readerName: "Adobe Photoshop",
        fileVersion: 1,
      },
    },
  };
  const buffer = writePsdBuffer(psd, {
    generateThumbnail: false,
    trimImageData: false,
    noBackground: true,
  });
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, buffer);
  process.stdout.write(JSON.stringify({
    outputPath,
    bytes: buffer.length,
    artboards: screenGroups.length,
    layers: manifest.screens.reduce((total, screen) => total + screen.layers.length, 0),
  }));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
