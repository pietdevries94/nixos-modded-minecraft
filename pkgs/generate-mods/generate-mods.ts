// deno-lint-ignore-file camelcase
import yargs from 'https://deno.land/x/yargs@v17.2.1-deno/deno.ts'
import { Arguments } from 'https://deno.land/x/yargs@v17.2.1-deno/deno-types.ts'
import { bold } from 'https://deno.land/x/nanocolors@0.1.12/mod.ts';
import Ajv, {JSONSchemaType} from 'https://cdn.skypack.dev/ajv?dts';
const ajv = new Ajv();

yargs(Deno.args)
  .scriptName("generate-mods")
  // deno-lint-ignore no-explicit-any
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
  source: "curseforge" | "directurl" | "modrinth",
  value: string | number,
  server?: boolean,
  client?: boolean
}

// This is not a complete interface, only what is used for this script
interface CurseForgeFile {
  id: number,
  gameVersion: string[],
  downloadUrl: string
}

interface ModrinthVersion {
  id: string,
  game_versions: string[],
  files: {url: string}[]
}

const schema: JSONSchemaType<JsonInput> = {
  type: "object",
  properties: {
    minecraftVersion: {type: "string"},
    mods: {
      type: "array",
      items: {
        type: "object",
        properties: {
          name: {type: "string"},
          source: {type: "string", enum: ["curseforge", "directurl", "modrinth"]},
          value: {type: ["string", "integer"]},
          server: {type: "boolean", nullable: true},
          client: {type: "boolean", nullable: true}
        },
        additionalProperties: false,
        required: ["name", "source", "value"],
      }
    },
  },
  required: ["minecraftVersion", "mods"],
  additionalProperties: false
}

const validateJsonInput = ajv.compile(schema)

async function getUrlFromCurseforgeForVersionAndMod(version: string, mod: number): Promise<string> {
  const jsonResponse = await fetch(`https://addons-ecs.forgesvc.net/api/v2/addon/${mod}/files`);
  const files: CurseForgeFile[] = await jsonResponse.json();

  const sortedFiles = files.sort((a, b) => b.id - a.id)
  const file = sortedFiles.find(f => f.gameVersion.includes(version))

  if (file) return file.downloadUrl;

  const splittedVersion = version.split(".")
  if (splittedVersion.length < 3) throw "unknown mod";
  const majorVersion = splittedVersion[0] + "." + splittedVersion[1]

  return getUrlFromCurseforgeForVersionAndMod(majorVersion, mod)
}

async function getUrlFromModrinthForVersionAndMod(version: string, mod: string): Promise<string> {
  const jsonResponse = await fetch(`https://api.modrinth.com/api/v1/mod/${mod}/version`);
  const versions: ModrinthVersion[] = await jsonResponse.json();

  const v = versions.find(f => f.game_versions.includes(version))

  if (v) return v.files[0].url;

  const splittedVersion = version.split(".")
  if (splittedVersion.length < 3) throw "unknown mod";
  const majorVersion = splittedVersion[0] + "." + splittedVersion[1]

  return getUrlFromModrinthForVersionAndMod(majorVersion, mod)
}

async function getHash(url: string): Promise<string> {
  const p = Deno.run({ cmd: ["nix-prefetch-url", url], stdout: 'piped', });
  const buf = await p.output()
  const out = new TextDecoder().decode(buf)
  return out.replace(/[\n\r]/g, '');
}

async function getJsonInput(jsonPath: string): Promise<{data: JsonInput, ok: boolean}> {
  const text = await Deno.readTextFile(jsonPath)
  const data = JSON.parse(text)
  const ok =  validateJsonInput(data)
  if (!ok) console.log(validateJsonInput.errors)
  return {data, ok}
}

async function generateNix(jsonPath: string, outputPath: string) {
  const {data: jsonInput, ok} = await getJsonInput(jsonPath)
  if (!ok) return;

  const modPromises = jsonInput.mods.map(async mod => {
    console.log(`Preparing ${bold('%s')} mod: ${bold('%s')}`, mod.source, mod.name)

    let url: string
    switch (mod.source) {
      case "curseforge":
        url = await getUrlFromCurseforgeForVersionAndMod(jsonInput.minecraftVersion, Number(mod.value))
        break
      case "modrinth":
        url = await getUrlFromModrinthForVersionAndMod(jsonInput.minecraftVersion, String(mod.value))
        break
      case "directurl":
        url = String(mod.value)
    }
  
    return `
  ${mod.name} = {
    client = ${mod.client ? "true" : "false"};
    server = ${mod.server ? "true" : "false"};
    src = pkgs.fetchurl {
      url = ${url};
      sha256 = "${await getHash(url)}";
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
