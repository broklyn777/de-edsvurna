// Plockar ut några namngivna delar ur en glb till en egen liten glb (skelettet behålls, andra
// meshar tas bort, animationerna behålls så att andra figurer kan låna dem). Används för Paladinens mantel
// och solemblem, Brokks hjälm och Alvas animationer ur sigrun.glb.
// Med --anims=A,B behålls bara de animationerna (de som lånas).
//   node tools/extract_parts.mjs in.glb ut.glb [--anims=OneHand_Idle,Hit_Chest] Sigrun_Cape Sigrun_SunEmblem ...
import { createRequire } from 'module';
import os from 'os';
const require = createRequire(os.homedir() + '/.npm/_npx/425967af1abfabd4/node_modules/');
const { NodeIO } = require('@gltf-transform/core');
const { ALL_EXTENSIONS } = require('@gltf-transform/extensions');
const { prune } = require('@gltf-transform/functions');

const [input, output, ...rest] = process.argv.slice(2);
const animArg = rest.find((a) => a.startsWith('--anims='));
const keepAnims = animArg ? animArg.slice(8).split(',') : null;
const keep = rest.filter((a) => !a.startsWith('--'));
// Utan namngivna delar behålls alla meshar (bara animationerna gallras).
const keepAll = keep.length === 0;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS);
const doc = await io.read(input);
const root = doc.getRoot();
// Godot bygger bara ett Skeleton3D när en hudbunden mesh finns kvar, så den minsta hudbundna meshen
// behålls (den används inte, men riggen och animationernas spår förblir desamma).
const meshBytes = (m) => m.listPrimitives().reduce((n, p) => n + p.listAttributes().reduce((k, a) => k + a.getByteLength(), 0), 0);
const skinned = root.listNodes().filter((n) => n.getMesh() && n.getSkin()).sort((a, b) => meshBytes(a.getMesh()) - meshBytes(b.getMesh()));
if (!keepAll && skinned.length && !keep.some((k) => skinned.some((n) => n.getName() === k))) keep.push(skinned[0].getName());
for (const node of root.listNodes()) {
	if (node.getMesh() && !keepAll && !keep.includes(node.getName())) {
		node.setMesh(null);
		node.setSkin(null);
	}
}
for (const anim of root.listAnimations()) {
	if (keepAnims && !keepAnims.includes(anim.getName())) anim.dispose();
}
await doc.transform(prune({ keepLeaves: true }));
await io.write(output, doc);
const missing = keepAll ? [] : keep.filter((n) => !root.listNodes().some((x) => x.getName() === n && x.getMesh()));
console.log(missing.length ? 'Saknas: ' + missing.join(', ') : 'OK: ' + keep.length + ' delar');
