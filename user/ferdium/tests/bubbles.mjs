// Generate a self-contained browser regression fixture from the actual theme.
// node tests/bubbles.mjs /nix/store/...-ferdium-amethyst-aero > /tmp/bubbles.html
import fs from 'node:fs';
import path from 'node:path';
const pkg = process.argv[2];
if (!pkg) throw new Error('Pass the built Ferdium Aero package');
const css = fs.readFileSync(path.join(pkg, 'share/amethyst-aero/messenger.css'), 'utf8');
const js = fs.readFileSync(new URL('../messenger-aero.js', import.meta.url), 'utf8');
process.stdout.write(`<!doctype html><html><head><meta charset="utf-8"><title>Messenger Aero regression fixture</title><style>
${css}
body{margin:0;padding:22px;font:15px system-ui;background:transparent!important}.panel{padding:20px;border:1px solid #67517f;border-radius:12px;background:#160f23}.messages{padding:20px 0}.row{display:flex;margin:12px 0}.out{justify-content:flex-end}.bubble{padding:12px 18px;border-radius:22px;background:#352547;max-width:80%}.native-backplate{display:inline-block;background:#0084ff;position:relative}.native-backplate .bubble{max-width:none}.reaction{position:absolute;bottom:-10px;right:0;width:25px;height:25px;padding:0;border:1px solid #67517f;border-radius:50%;background:#f29ba9;color:#190f23}small{color:#baaacb}.compose{padding:10px;background:#241934}
</style></head><body><div class="panel"><strong>Messenger · poprawione warstwy dymków</strong><br><small>Dane przykładowe, z celowo dodanym niebieskim podkładem.</small>
<section data-scope="messages_table" class="messages">
<div class="row" role="row" id="broad-row" style="background:#1d2233"><div role="gridcell"><div class="bubble" id="incoming"><span dir="auto">Wiadomość odebrana</span></div></div></div>
<div class="row out" role="row"><div role="gridcell"><div class="native-backplate" id="backing"><div class="bubble" id="outgoing"><span dir="auto">Wiadomość wysłana</span></div><button class="reaction" id="reaction">♥</button></div></div></div>
<div class="row" role="row"><div class="bubble" id="media"><img alt="Załącznik" width="80" height="25" src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='80' height='25'%3E%3Crect width='80' height='25' fill='%2383c6ac'/%3E%3C/svg%3E"><span dir="auto">Załącznik</span></div></div>
</section><div class="compose" role="textbox" contenteditable="true" dir="auto" id="composer">Aa</div><small id="result">Sprawdzanie…</small></div>
<script>const module={exports:null};${js};module.exports();
window.aeroFixtureErrors=[];
function check(condition,message){if(!condition){window.aeroFixtureErrors.push(message);console.error(message);}}
check(document.querySelector('#incoming').dataset.aeroMessage==='incoming','Incoming classification');
check(document.querySelector('#outgoing').dataset.aeroMessage==='outgoing','Outgoing classification');
check(getComputedStyle(document.querySelector('#backing')).backgroundColor==='rgba(0, 0, 0, 0)','Blue backing must be transparent');
check(getComputedStyle(document.querySelector('#reaction')).backgroundColor==='rgb(242, 155, 169)','Reaction keeps its own background');
check(!document.querySelector('#broad-row').hasAttribute('data-aero-bubble-backing'),'Message row is not a bubble backing');
check(!document.querySelector('#media').hasAttribute('data-aero-message'),'Attachment untouched');
check(!document.querySelector('#composer').hasAttribute('data-aero-message'),'Composer untouched');
const row=document.createElement('div');row.className='row out';row.setAttribute('role','row');row.innerHTML='<div role="gridcell"><div class="native-backplate" id="new-backing"><div class="bubble" id="new-message"><span dir="auto">Nowa wiadomość też bez niebieskiego tła</span></div></div></div>';document.querySelector('.messages').append(row);
setTimeout(()=>{check(document.querySelector('#new-message').dataset.aeroMessage==='outgoing','New message classification');check(getComputedStyle(document.querySelector('#new-backing')).backgroundColor==='rgba(0, 0, 0, 0)','New blue backing transparent');document.querySelector('#result').textContent=window.aeroFixtureErrors.length?'Test nie przeszedł':'Wszystkie testy przeszły';console.log({errors:window.aeroFixtureErrors});},350);
</script></body></html>`);
