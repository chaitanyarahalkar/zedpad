/* ─── Intersection Observer — fade-in on scroll ──────────────────────────── */
const observer = new IntersectionObserver(
  (entries) => entries.forEach(e => { if (e.isIntersecting) e.target.classList.add('visible'); }),
  { threshold: 0.12 }
);
document.querySelectorAll('.fade-up').forEach(el => observer.observe(el));

/* ─── Counter animation ──────────────────────────────────────────────────── */
function animateCounter(el, target, suffix = '') {
  const duration = 1800;
  const start = performance.now();
  const update = (now) => {
    const progress = Math.min((now - start) / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3);
    el.textContent = Math.floor(eased * target).toLocaleString() + suffix;
    if (progress < 1) requestAnimationFrame(update);
  };
  requestAnimationFrame(update);
}

const statObserver = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (!e.isIntersecting) return;
    const el = e.target;
    const raw = el.dataset.target;
    const suffix = el.dataset.suffix || '';
    animateCounter(el, parseInt(raw), suffix);
    statObserver.unobserve(el);
  });
}, { threshold: 0.5 });

document.querySelectorAll('[data-target]').forEach(el => statObserver.observe(el));

/* ─── Typewriter effect in hero ──────────────────────────────────────────── */
const lines = [
  { indent: 0, html: '<span class="c-attr">@Published</span> <span class="c-kw">var</span> <span class="c-fn">content</span>: <span class="c-type">String</span> = <span class="c-str">""</span>' },
  { indent: 0, html: '' },
  { indent: 0, html: '<span class="c-kw">func</span> <span class="c-fn">highlight</span>(<span class="c-fn">_</span> text: <span class="c-type">String</span>) {' },
  { indent: 1, html: '<span class="c-kw">let</span> tokens = <span class="c-fn">SyntaxHighlighter</span>' },
  { indent: 2, html: '.<span class="c-fn">tokenize</span>(text, language: .<span class="c-fn">swift</span>)' },
  { indent: 1, html: '<span class="c-kw">return</span> tokens.<span class="c-fn">map</span> { <span class="c-fn">colorize</span>(<span class="c-fn">$0</span>) }' },
  { indent: 0, html: '}' },
  { indent: 0, html: '' },
  { indent: 0, html: '<span class="c-cm">// 21 languages. All local. Zero latency.</span>' },
];

const codeContent = document.getElementById('typewriter');
const lineNums = document.getElementById('line-nums');

if (codeContent) {
  let lineIndex = 0;

  function typeLine() {
    if (lineIndex >= lines.length) return;

    const line = lines[lineIndex];
    const lineEl = document.createElement('div');
    lineEl.innerHTML = '  '.repeat(line.indent) + line.html;
    codeContent.appendChild(lineEl);

    // Update line numbers
    lineNums.textContent = Array.from({ length: lineIndex + 1 }, (_, i) => i + 1).join('\n');

    lineIndex++;
    setTimeout(typeLine, lineIndex === 1 ? 200 : 180 + Math.random() * 120);
  }

  setTimeout(typeLine, 600);
}

/* ─── Subtle parallax on hero glow orbs ─────────────────────────────────── */
const glows = document.querySelectorAll('.hero-glow');
document.addEventListener('mousemove', (e) => {
  const cx = window.innerWidth / 2;
  const cy = window.innerHeight / 2;
  const dx = (e.clientX - cx) / cx;
  const dy = (e.clientY - cy) / cy;
  glows.forEach((g, i) => {
    const factor = i === 0 ? 18 : -14;
    g.style.transform = `translate(${dx * factor}px, ${dy * factor}px)`;
  });
});

/* ─── Smooth active nav link ─────────────────────────────────────────────── */
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-links a[href^="#"]');

window.addEventListener('scroll', () => {
  let current = '';
  sections.forEach(s => {
    if (window.scrollY >= s.offsetTop - 100) current = s.id;
  });
  navLinks.forEach(a => {
    a.style.color = a.getAttribute('href') === `#${current}` ? 'var(--blue)' : '';
  });
}, { passive: true });
