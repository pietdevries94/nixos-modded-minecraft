// needed for the language server
export { };

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
  let file = sortedFiles.find(f => f.gameVersion.includes(version))

  if (file) return file;

  const splittedVersion = version.split(".")
  if (splittedVersion.length < 3) throw "unknown mod";
  const majorVersion = splittedVersion[0] + "." + splittedVersion[1]

  return getFileFromCurseforgeForVersionAndMod(majorVersion, mod)
}

async function getHash(url: string): Promise<string> {
  // @ts-ignore Deno is defined, but vscode isn't happy yet
  const p = Deno.run({ cmd: ["nix-prefetch-url", url], stdout: 'piped', });
  const buf = await p.output()
  const out = new TextDecoder().decode(buf)
  return out.replace(/[\n\r]/g, '');
}

async function getJsonInput(): Promise<JsonInput> {
  // @ts-ignore Deno is defined, but vscode isn't happy yet
  const text = await Deno.readTextFile(Deno.args[0])
  return JSON.parse(text)
}

const jsonInput = await getJsonInput()

const modPromises = jsonInput.mods.map(async mod => {
  let file: File
  switch (mod.source) {
    case "curseforge":
      file = await getFileFromCurseforgeForVersionAndMod(jsonInput.minecraftVersion, 306612)
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

[${(await Promise.all(modPromises)).join()}
]
`

// @ts-ignore Deno is defined, but vscode isn't happy yet
if (Deno.args[1])
  // @ts-ignore Deno is defined, but vscode isn't happy yet
  Deno.writeTextFile(Deno.args[1], res)
else
  console.log(res)
