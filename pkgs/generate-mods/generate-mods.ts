import yargs from 'https://deno.land/x/yargs@v17.2.1-deno/deno.ts'
import { Arguments } from 'https://deno.land/x/yargs@v17.2.1-deno/deno-types.ts'
import { bold } from 'https://deno.land/x/nanocolors@0.1.12/mod.ts';

yargs(Deno.args)
  .scriptName("generate-mods")
  .command('generate <source> <target>', 'generates the nix output for the json to target path', (yargs: any) => {
    return yargs.positional('source', {
      describe: 'the source json'
    }).positional('target', {
      describe: 'the target file'
    })
  }, (argv: Arguments) => {
    generateNix(argv.source, argv.target)
  })
  .strictCommands()
  .demandCommand(1)
  .parse()

interface JsonInput {
  minecraftVersion: string,
  mods: ModDefinition[]
}

interface ModDefinition {
  name: string,
  source: "curseforge",
  id: number,
  server?: boolean,
  client?: boolean
}

// This is not a complete interface, only what is used for this script
interface File {
  id: number,
  gameVersion: string[],
  downloadUrl: string
}

async function getFileFromCurseforgeForVersionAndMod(version: string, mod: number): Promise<File> {
  const jsonResponse = await fetch(`https://addons-ecs.forgesvc.net/api/v2/addon/${mod}/files`);
  const files: File[] = await jsonResponse.json();

  const sortedFiles = files.sort((a, b) => b.id - a.id)
  const file = sortedFiles.find(f => f.gameVersion.includes(version))

  if (file) return file;

  const splittedVersion = version.split(".")
  if (splittedVersion.length < 3) throw "unknown mod";
  const majorVersion = splittedVersion[0] + "." + splittedVersion[1]

  return getFileFromCurseforgeForVersionAndMod(majorVersion, mod)
}

async function getHash(url: string): Promise<string> {
  const p = Deno.run({ cmd: ["nix-prefetch-url", url], stdout: 'piped', });
  const buf = await p.output()
  const out = new TextDecoder().decode(buf)
  return out.replace(/[\n\r]/g, '');
}

async function getJsonInput(jsonPath: string): Promise<JsonInput> {
  const text = await Deno.readTextFile(jsonPath)
  return JSON.parse(text)
}

async function generateNix(jsonPath: string, outputPath: string) {
  const jsonInput = await getJsonInput(jsonPath)

  const modPromises = jsonInput.mods.map(async mod => {
    console.log(`Preparing ${bold('%s')} mod: ${bold('%s')}`, mod.source, mod.name)

    let file: File
    switch (mod.source) {
      case "curseforge":
        file = await getFileFromCurseforgeForVersionAndMod(jsonInput.minecraftVersion, mod.id)
    }
  
    return `
  ${mod.name} = {
    client = ${mod.client ? "true" : "false"};
    server = ${mod.server ? "true" : "false"};
    src = pkgs.fetchurl {
      url = ${file.downloadUrl};
      sha256 = "${await getHash(file.downloadUrl)}";
    };
  };`
  })
  
  const res = `{ pkgs }:

{${(await Promise.all(modPromises)).join('')}
}
`
  console.log("Succesfully preloaded all mods")
  console.log(`Writing output to ${bold('%s')}`, outputPath)
  Deno.writeTextFile(outputPath, res)
}
