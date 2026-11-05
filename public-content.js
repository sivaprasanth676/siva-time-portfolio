(() => {
  const cfg = window.SIVA_CONFIG || {};
  if (!window.supabase || !cfg.SUPABASE_URL || !cfg.SUPABASE_ANON_KEY) return;
  const db = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);
  const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const projectsHost = document.querySelector('#projects .projects-grid');
  const journalHost = document.querySelector('#journal .journal-list');

  async function loadProjects() {
    if (!projectsHost) return;
    const { data, error } = await db.from('projects').select('id,title,category,summary,image_url,project_url,sort_order').eq('published', true).order('sort_order', { ascending: true }).order('created_at', { ascending: false });
    if (error || !data?.length) return; // Keep the existing designed fallback if no published records exist.
    projectsHost.innerHTML = data.map((p, i) => {
      const artClass = ['art-law','art-ai','art-creative'][i % 3];
      const visual = p.image_url ? `<img src="${esc(p.image_url)}" alt="${esc(p.title)}" loading="lazy" style="width:100%;height:100%;object-fit:cover">` : `<span class="art-label">${esc(p.category || 'PROJECT')} / ${String(i+1).padStart(2,'0')}</span><div class="art-graphic">${i===0?'§':i===1?'⌘':'◈'}</div><span class="art-caption">SIVA TIME / SELECTED WORK</span>`;
      const link = p.project_url ? `<a href="${esc(p.project_url)}" target="_blank" rel="noopener" aria-label="View ${esc(p.title)}">↗</a>` : '<span aria-hidden="true">↗</span>';
      return `<article class="project-card ${i===0?'project-feature':''} reveal"><div class="project-art ${artClass}">${visual}</div><div class="project-info"><div><span class="project-type">${esc(p.category)}</span><h3>${esc(p.title)}</h3></div><p>${esc(p.summary)}</p>${link}</div></article>`;
    }).join('');
    projectsHost.querySelectorAll('.reveal').forEach(el => el.classList.add('visible'));
  }

  async function loadArticles() {
    if (!journalHost) return;
    const { data, error } = await db.from('articles').select('id,title,category,excerpt,slug,published_at').eq('published', true).order('published_at', { ascending: false, nullsFirst: false }).order('created_at', { ascending: false });
    if (error || !data?.length) return; // Keep the existing designed fallback if no published records exist.
    journalHost.innerHTML = data.map((a, i) => {
      const href = a.slug ? `article.html?slug=${encodeURIComponent(a.slug)}` : '#contact';
      return `<a href="${href}"><span>${String(i+1).padStart(2,'0')}</span><b>${esc(a.title)}</b><small>${esc(a.category || 'JOURNAL')}</small><i>↗</i></a>`;
    }).join('');
  }
  loadProjects();
  loadArticles();
})();
