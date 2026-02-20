# Setup Prompt

Aşağıdaki prompt'u Claude Code'a yapıştır. Sana hangi parçaları istediğini soracak ve otomatik kuracak.

---

```
Bana bir Claude Code plugin sistemi kurman lazım. Repo: https://github.com/bulbulogludemir/claude-code-plugins

Önce şunları yap:
1. `jq` kurulu mu kontrol et, değilse kur (brew install jq)
2. Repoyu ~/Projects/claude-code-plugins dizinine clone'la (varsa git pull yap)

Sonra bana sor: Hangi parçaları kurmak istiyorum? Seçenekler:

**Plugin grupları:**
- **Core** (claude-core) — Temel: explorer agent, quality-gate hook'ları, implement/planning skill'leri, TypeScript/security/performance/testing/git kuralları. HERKESİN KURMASI GEREKİR.
- **Frontend** (claude-frontend) — UI geliştirme: frontend/i18n agents, component/styling/accessibility/performance/SEO skill'leri
- **Backend** (claude-backend) — API & veritabanı: backend/database/security/analytics agents, API/DB/integrations/monitoring/email/AI skill'leri
- **Mobile** (claude-mobile) — Mobil: mobile agent, Expo/React Native/NativeWind skill'leri
- **DevOps** (claude-devops) — Altyapı: devops agent, release skill, deploy hook'ları
- **Quality** (claude-quality) — QA: reviewer agent, quality/bugfix/error-recovery skill'leri
- **DevTools** (claude-devtools) — Git & code review: review-plan/refactor skill'leri, pre-commit hook

**Ekstra:**
- **CLAUDE.md** — Global kurallar (execution mode, quality gates, tech stack tanımları). Önerilir.
- **Settings template** — Hook konfigürasyonu (rm -rf koruması, force push koruması, quality gate, statusline). Önerilir.

**External plugin'ler:**
- typescript-lsp — TypeScript dil sunucusu
- stripe — Stripe entegrasyonu
- supabase — Supabase entegrasyonu
- sentry — Sentry hata takibi
- vercel — Vercel deployment
- indexandria — Dokümantasyon indexleme

Seçimlerime göre `bash install.sh` komutunu uygun parametrelerle çalıştır. Eğer "hepsini kur" dersem parametresiz çalıştır. Eğer belirli plugin'ler seçersem sadece onları kur (örn: `bash install.sh claude-core claude-frontend`).

CLAUDE.md ve settings template'i istemiyorsam, kurulumdan sonra şu symlink'leri kaldır:
- CLAUDE.md istemiyorsam: rm ~/.claude/CLAUDE.md
- Settings istemiyorsam: settings.json'a dokunma (install.sh merge etmesin)

External plugin'ler için ayrı ayrı sor ve seçtiklerimi `claude plugin install` ile kur.

Kurulum bittikten sonra özet ver: ne kuruldu, ne kurulmadı, restart gerekiyor mu.
```
