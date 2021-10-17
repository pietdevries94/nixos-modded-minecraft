// needed for the language server
export { };

const mcVersion = "1.17.1"

// This is not a complete interface, only what is used for this script
interface File {
  id: number,
  gameVersion: string[],
  downloadUrl: string
}

const jsonResponse = await fetch("https://addons-ecs.forgesvc.net/api/v2/addon/306612/files");
const files: File[] = await jsonResponse.json();

const sortedFiles = files.sort((a, b) => b.id - a.id)
let file = files.find(f => f.gameVersion.includes(mcVersion))
// TODO fallback to minor version of minecraft if there is a patch given and the mod doesn't directly supports it

console.log(file?.downloadUrl)