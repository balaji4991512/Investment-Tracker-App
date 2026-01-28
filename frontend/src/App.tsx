import { useState, useEffect } from 'react'
import './App.css'

type UploadState = 'idle' | 'uploading' | 'done' | 'error'
type ModalStep = 'upload' | 'review'

interface SavedInvestment {
  id: string
  bill_id: string
  category: string
  name: string
  vendor: string | null
  date: string | null
  total_amount: number
  weight_grams: number | null
  purity_karat: number | null
  gold_rate_per_gram: number | null
  making_charges: number | null
  metadata: any
}

type GoldTodayResponse = {
  date: string
  inr_per_gram: Record<string, number>
  source: string
  captured_at_ist?: string
}

function App() {
  const [investments, setInvestments] = useState<SavedInvestment[]>([])
  const [activeView, setActiveView] = useState<'home' | 'gold_list' | 'diamond_list'>('home')
  const [goldToday, setGoldToday] = useState<GoldTodayResponse | null>(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [modalStep, setModalStep] = useState<ModalStep>('upload')
  const [uploadState, setUploadState] = useState<UploadState>('idle')
  const [extractedJson, setExtractedJson] = useState<string>('')
  const [errorMessage, setErrorMessage] = useState<string>('')
  const [selectedCategory, setSelectedCategory] = useState<'gold' | 'diamond'>('gold')
  const [billId, setBillId] = useState<string | null>(null)

  // Review fields mapped from extracted JSON
  const [vendorName, setVendorName] = useState('')
  const [purchaseDate, setPurchaseDate] = useState('')
  const [productName, setProductName] = useState('')

  const [netMetalWeight, setNetMetalWeight] = useState('')
  const [stoneWeight, setStoneWeight] = useState('')
  const [grossWeight, setGrossWeight] = useState('')

  const [goldPrice, setGoldPrice] = useState('')
  const [makingChargesPerGram, setMakingChargesPerGram] = useState('')
  const [stoneCost, setStoneCost] = useState('')
  const [grossPrice, setGrossPrice] = useState('')
  const [gsts, setGsts] = useState('')
  const [discounts, setDiscounts] = useState('')
  const [finalPrice, setFinalPrice] = useState('')
  const [goldPurity, setGoldPurity] = useState('')

  // Load investments on mount
  const loadInvestments = async () => {
    try {
      const res = await fetch('http://127.0.0.1:8000/investments/')
      if (res.ok) {
        const data = await res.json()
        setInvestments(data)
      }
    } catch (err) {
      console.error('Failed to load investments:', err)
    }
  }

  useEffect(() => {
    loadInvestments()
  }, [])

  useEffect(() => {
    const loadGold = async () => {
      try {
        const res = await fetch('http://127.0.0.1:8000/rates/gold/today')
        if (res.ok) {
          const data = await res.json()
          setGoldToday(data)
          ;(window as any).__goldTodayRates = data
        }
      } catch (err) {
        console.error('Failed to load gold rate:', err)
      }
    }
    loadGold()
  }, [])

  // Compute totals
  const totalInvested = investments.reduce((sum, inv) => sum + (inv.total_amount || 0), 0)
  const goldInvestments = investments.filter(inv => inv.category === 'gold_jewellery')
  const diamondInvestments = investments.filter(inv => inv.category === 'diamond_jewellery')
  const goldTotal = goldInvestments.reduce((sum, inv) => sum + (inv.total_amount || 0), 0)
  const diamondTotal = diamondInvestments.reduce((sum, inv) => sum + (inv.total_amount || 0), 0)

  const currentGoldValue = (() => {
    if (!goldToday) return 0
    return goldInvestments.reduce((sum, inv) => {
      const k = inv.purity_karat ?? 24
      const rate = goldToday.inr_per_gram[String(k)] ?? goldToday.inr_per_gram['24']
      const w = inv.weight_grams ?? 0
      return sum + rate * w
    }, 0)
  })()

  const returnAmount = currentGoldValue - totalInvested
  const returnPct = totalInvested > 0 ? (returnAmount / totalInvested) * 100 : 0

  const computeXirr = (cashflows: { date: Date, amount: number }[]) => {
    if (cashflows.length < 2) return null
    const t0 = cashflows[0].date.getTime()
    const years = (d: Date) => (d.getTime() - t0) / (365.25 * 24 * 3600 * 1000)
    const npv = (rate: number) => cashflows.reduce((s, cf) => s + cf.amount / Math.pow(1 + rate, years(cf.date)), 0)
    let lo = -0.9999
    let hi = 10
    let fLo = npv(lo)
    let fHi = npv(hi)
    if (Number.isNaN(fLo) || Number.isNaN(fHi) || fLo * fHi > 0) return null
    for (let i = 0; i < 80; i++) {
      const mid = (lo + hi) / 2
      const fMid = npv(mid)
      if (Math.abs(fMid) < 1e-7) return mid
      if (fLo * fMid <= 0) {
        hi = mid
        fHi = fMid
      } else {
        lo = mid
        fLo = fMid
      }
    }
    return (lo + hi) / 2
  }

  const portfolioXirr = (() => {
    if (!goldToday) return null
    const flows: { date: Date, amount: number }[] = []
    for (const inv of investments) {
      if (!inv.date || !inv.total_amount) continue
      const d = new Date(inv.date)
      if (isNaN(d.getTime())) continue
      flows.push({ date: d, amount: -inv.total_amount })
    }
    // terminal cashflow = current portfolio value today
    flows.sort((a, b) => a.date.getTime() - b.date.getTime())
    flows.push({ date: new Date(), amount: currentGoldValue })
    return computeXirr(flows)
  })()

  const deleteInvestment = async (id: string) => {
    if (!confirm('Delete this investment?')) return
    try {
      const res = await fetch(`http://127.0.0.1:8000/investments/${id}`, { method: 'DELETE' })
      if (!res.ok) {
        const text = await res.text()
        throw new Error(text || 'Failed to delete')
      }
      await loadInvestments()
    } catch (err) {
      console.error('Delete failed:', err)
      alert('Failed to delete investment')
    }
  }

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    setUploadState('uploading')
    setErrorMessage('')
    setExtractedJson('')
    setBillId(null)
    setVendorName('')
    setPurchaseDate('')
    setProductName('')
    setNetMetalWeight('')
    setStoneWeight('')
    setGrossWeight('')
    setGoldPrice('')
    setMakingChargesPerGram('')
    setStoneCost('')
    setGrossPrice('')
    setGsts('')
    setDiscounts('')
    setFinalPrice('')
    setGoldPurity('')
    setModalStep('upload')

    try {
      const formData = new FormData()
      formData.append('file', file)

      const res = await fetch('http://127.0.0.1:8000/bills/upload', {
        method: 'POST',
        body: formData,
      })

      if (!res.ok) {
        const text = await res.text()
        throw new Error(text || 'Upload failed')
      }

      const data = await res.json()

      // Store bill id
      if (data.bill_id && typeof data.bill_id === 'string') {
        setBillId(data.bill_id)
      }

      // Map fields from extracted JSON using new strict schema keys
      const extracted = data.extracted || {}
      console.log('[App] extracted keys:', Object.keys(extracted))
      console.log('[App] extracted:', extracted)

      try {
        // New schema: vendor, productName, purchaseDate, netMetalWeight, stoneWeight, grossWeight,
        // grossPrice, gst { cgst, sgst, total }, discounts, finalPrice, goldPurity, goldRatePerGram
        const vendorVal = extracted.vendor ?? ''
        const descVal = extracted.productName ?? ''
        const dateVal = extracted.purchaseDate ?? ''
        const netW = extracted.netMetalWeight ?? null
        const stoneW = extracted.stoneWeight ?? null
        const grossW = extracted.grossWeight ?? null
        const goldRate = extracted.goldRatePerGram ?? null
        const makingPG = extracted.makingChargesPerGram ?? null
        const stone = extracted.stoneCost ?? null
        const metalValue = extracted.grossPrice ?? null
        const finalAmount = extracted.finalPrice ?? null
        const discountVal = extracted.discounts ?? null
        const purityVal = extracted.goldPurity ?? ''

        // GST: prefer total, else sum cgst + sgst
        const gstObj = extracted.gst ?? {}
        let gstTotal = gstObj.total ?? null
        if (gstTotal == null && (gstObj.cgst != null || gstObj.sgst != null)) {
          gstTotal = (gstObj.cgst ?? 0) + (gstObj.sgst ?? 0)
        }

        setVendorName(vendorVal ? String(vendorVal) : '')
        setProductName(descVal ? String(descVal) : '')
        setPurchaseDate(dateVal ? String(dateVal) : '')

        if (netW != null) setNetMetalWeight(String(netW))
        if (stoneW != null) setStoneWeight(String(stoneW))
        if (grossW != null) setGrossWeight(String(grossW))
        if (goldRate != null) setGoldPrice(String(goldRate))
        if (makingPG != null) setMakingChargesPerGram(String(makingPG))
        if (stone != null) setStoneCost(String(stone))
        if (metalValue != null) setGrossPrice(String(metalValue))
        if (gstTotal != null) setGsts(String(gstTotal))
        if (discountVal != null) setDiscounts(String(discountVal))
        if (finalAmount != null) setFinalPrice(String(finalAmount))
        if (purityVal) setGoldPurity(String(purityVal))

        setExtractedJson(JSON.stringify(extracted, null, 2))
      } catch {
        setExtractedJson(typeof data.extracted === 'string' ? data.extracted : JSON.stringify(data.extracted, null, 2))
      }
      setUploadState('done')
      setModalStep('review')
    } catch (err: any) {
      setUploadState('error')
      setErrorMessage(err?.message ?? 'Something went wrong while processing the bill.')
    }
  }

  const handleSaveInvestment = async () => {
    if (!billId || !finalPrice) return
    setErrorMessage('')

    try {
      const toNumber = (v: string) => {
        if (v == null) return null
        const t = String(v).trim()
        if (t === '') return null
        const n = Number(t)
        return Number.isFinite(n) ? n : null
      }

      let metadata: any = null
      try {
        metadata = extractedJson ? JSON.parse(extractedJson) : null
      } catch {
        metadata = null
      }

      const payload = {
        bill_id: billId,
        category: selectedCategory === 'gold' ? 'gold_jewellery' : 'diamond_jewellery',
        name: productName || 'Jewellery investment',
        vendor: vendorName || null,
        date: purchaseDate || null,
        total_amount: toNumber(finalPrice),
        weight_grams: toNumber(netMetalWeight),
        purity_karat: goldPurity ? parseInt(String(goldPurity).replace(/[^0-9]/g, ''), 10) || null : null,
        gold_rate_per_gram: toNumber(goldPrice),
        making_charges: toNumber(makingChargesPerGram),
        metadata,
      }

      const res = await fetch('http://127.0.0.1:8000/investments/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })

      if (!res.ok) {
        const text = await res.text()
        throw new Error(text || 'Failed to save investment')
      }

      // Reload investments and close modal
      await loadInvestments()
      setIsModalOpen(false)
    } catch (err: any) {
      setErrorMessage(err?.message ?? 'Failed to save investment')
    }
  }

  return (
    <div className="app-root">
      <div className="app-layout">
        <aside className="sidebar">
          <div className="sidebar-brand">
            <div className="brand-mark">IT</div>
            <div className="brand-text">
              <div className="brand-title">Invest</div>
              <div className="brand-sub">Tracker</div>
            </div>
          </div>

          <nav className="side-nav">
            <button className={activeView === 'home' ? 'side-nav-item active' : 'side-nav-item'} onClick={() => setActiveView('home')} type="button">
              Overview
            </button>
            <button className={activeView === 'gold_list' ? 'side-nav-item active' : 'side-nav-item'} onClick={() => setActiveView('gold_list')} type="button">
              Gold Jewellery
            </button>
            <button className={activeView === 'diamond_list' ? 'side-nav-item active' : 'side-nav-item'} onClick={() => setActiveView('diamond_list')} type="button">
              Diamond Jewellery
            </button>
          </nav>

          <div className="sidebar-foot">
            <div className="sidebar-foot-pill">
              <span className="dot" />
              Live rates
            </div>
          </div>
        </aside>

        <div className="main">
          <header className="topbar">
            <div className="topbar-left">
              <div className="topbar-title">{activeView === 'home' ? 'Overview' : activeView === 'gold_list' ? 'Gold Jewellery' : 'Diamond Jewellery'}</div>
              <div className="topbar-sub">Vibrant dark portfolio tracker</div>
            </div>
            <div className="topbar-right">
              {activeView !== 'home' && (
                <button className="secondary-btn" type="button" onClick={() => setActiveView('home')}>
                  Back
                </button>
              )}
              <button
                className="primary-btn"
                type="button"
                onClick={() => {
                  setIsModalOpen(true)
                  setModalStep('upload')
                }}
              >
                Add
              </button>
            </div>
          </header>

          <div className="app-shell">

        {activeView === 'home' && (
          <>
            {/* Header / Hero */}
            <header className="hero">
              <div>
                <p className="hero-kicker">investment tracker</p>
                <h1 className="hero-title">Your jewellery, under control.</h1>
              </div>
              <div className="hero-metric">
                <p className="hero-metric-label">total invested</p>
                <p className="hero-metric-value">₹{totalInvested.toLocaleString('en-IN')}</p>
              </div>
          <div className="hero-metric">
            <p className="hero-metric-label">current gold value</p>
            <p className="hero-metric-value">₹{Math.round(currentGoldValue).toLocaleString('en-IN')}</p>
          </div>
          <div className="hero-metric">
            <p className="hero-metric-label">return</p>
            <p className="hero-metric-value" style={{ color: returnAmount >= 0 ? '#5CFFA6' : '#FF7E7E' }}>
              {returnAmount >= 0 ? '+' : ''}₹{Math.round(returnAmount).toLocaleString('en-IN')} ({returnPct >= 0 ? '+' : ''}{returnPct.toFixed(2)}%)
            </p>
          </div>
          <div className="hero-metric">
            <p className="hero-metric-label">xirr</p>
            <p className="hero-metric-value" style={{ color: (portfolioXirr ?? 0) >= 0 ? '#5CFFA6' : '#FF7E7E' }}>
              {portfolioXirr == null ? '—' : `${(portfolioXirr * 100).toFixed(2)}%`}
            </p>
          </div>
            </header>

            {/* Categories */}
            <section className="categories">
              <CategoryCard
                title="Gold Jewellery"
                subtitle="Upload bills, track weight & purity"
                accent="gold"
                count={goldInvestments.length}
                total={goldTotal}
                onClick={() => setActiveView('gold_list')}
              />
              <CategoryCard
                title="Diamond Jewellery"
                subtitle="Capture every stone & certificate"
                accent="diamond"
                count={diamondInvestments.length}
                total={diamondTotal}
                onClick={() => setActiveView('diamond_list')}
              />
            </section>

            {/* Floating Add button */}
            <button
              className="fab"
              onClick={() => {
                setIsModalOpen(true)
                setModalStep('upload')
              }}
            >
              <span>＋</span>
              <span>Add investment</span>
            </button>
          </>
        )}

        {activeView === 'gold_list' && (
          <InvestmentList
            title="Gold Jewellery"
            investments={goldInvestments}
            onDelete={deleteInvestment}
          />
        )}

        {activeView === 'diamond_list' && (
          <InvestmentList
            title="Diamond Jewellery"
            investments={diamondInvestments}
            onDelete={deleteInvestment}
          />
        )}

        {isModalOpen && (
          <div className="modal-backdrop" onClick={() => setIsModalOpen(false)}>
            <div className="modal" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <p className="modal-kicker">smart add</p>
                <h2 className="modal-title">Add jewellery investment</h2>
              </div>

              {/* Category toggle */}
              <div className="category-toggle">
                <button
                  className={selectedCategory === 'gold' ? 'toggle-btn active' : 'toggle-btn'}
                  onClick={() => setSelectedCategory('gold')}
                >
                  Gold jewellery
                </button>
                <button
                  className={selectedCategory === 'diamond' ? 'toggle-btn active' : 'toggle-btn'}
                  onClick={() => setSelectedCategory('diamond')}
                >
                  Diamond jewellery
                </button>
              </div>

              {modalStep === 'upload' && (
                <div className="upload-card">
                  <p className="upload-title">Upload bill (PDF or image)</p>
                  <p className="upload-subtitle">
                    We&apos;ll read the bill with GPT‑4o Vision and auto‑fill your investment. You can correct everything on the next step.
                  </p>
                  <label className="upload-drop">
                    <input
                      type="file"
                      accept="application/pdf,image/*"
                      onChange={handleFileChange}
                      style={{ display: 'none' }}
                    />
                    <div className="upload-icon">📎</div>
                    <div>
                      <p className="upload-cta">Drop your bill here or click to browse</p>
                      <p className="upload-hint">Supported: PDF, JPG, PNG</p>
                    </div>
                  </label>

                  {uploadState === 'uploading' && (
                    <p className="upload-status">Processing bill with AI…</p>
                  )}
                  {uploadState === 'error' && (
                    <p className="upload-error">{errorMessage}</p>
                  )}
                </div>
              )}

              {modalStep === 'review' && (
                <div className="upload-card">
                  <p className="upload-title">Review &amp; edit fields</p>
                  <p className="upload-subtitle">We&apos;ve pre-filled these from your bill. Tweak anything before saving.</p>

                  <div className="review-grid">
                    <div className="review-field">
                      <label>Vendor Name</label>
                      <input className="field-input" value={vendorName} onChange={(e) => setVendorName(e.target.value)} />
                    </div>
                    <div className="review-field">
                      <label>Purchase Date</label>
                      <input className="field-input" value={purchaseDate} onChange={(e) => setPurchaseDate(e.target.value)} />
                    </div>

                    <div className="review-field full">
                      <label>Product Name</label>
                      <input className="field-input" value={productName} onChange={(e) => setProductName(e.target.value)} />
                    </div>

                    <div className="review-field">
                      <label>Net Metal Weight (g)</label>
                      <input className="field-input" value={netMetalWeight} onChange={(e) => setNetMetalWeight(e.target.value)} />
                    </div>
                    <div className="review-field">
                      <label>Stone Weight (g)</label>
                      <input className="field-input" value={stoneWeight} onChange={(e) => setStoneWeight(e.target.value)} />
                    </div>
                    <div className="review-field">
                      <label>Gross Weight (g)</label>
                      <input className="field-input" value={grossWeight} onChange={(e) => setGrossWeight(e.target.value)} />
                    </div>

                    <div className="review-field">
                      <label>Gold Purity</label>
                      <input className="field-input" value={goldPurity} onChange={(e) => setGoldPurity(e.target.value)} />
                    </div>
                    <div className="review-field">
                      <label>Gold Rate / gram (₹)</label>
                      <input className="field-input" value={goldPrice} onChange={(e) => setGoldPrice(e.target.value)} />
                    </div>
                    <div className="review-field">
                      <label>Making Charges / gram (₹)</label>
                      <input className="field-input" value={makingChargesPerGram} onChange={(e) => setMakingChargesPerGram(e.target.value)} />
                    </div>
                    <div className="review-field">
                      <label>Stone Cost (₹)</label>
                      <input className="field-input" value={stoneCost} onChange={(e) => setStoneCost(e.target.value)} />
                    </div>
                    <div className="review-field">
                      <label>Gross Price (₹)</label>
                      <input className="field-input" value={grossPrice} onChange={(e) => setGrossPrice(e.target.value)} />
                    </div>

                    <div className="review-field">
                      <label>GST (₹)</label>
                      <input className="field-input" value={gsts} onChange={(e) => setGsts(e.target.value)} />
                    </div>
                    <div className="review-field">
                      <label>Discounts (₹)</label>
                      <input className="field-input" value={discounts} onChange={(e) => setDiscounts(e.target.value)} />
                    </div>
                    <div className="review-field">
                      <label>Final Price (₹)</label>
                      <input className="field-input" value={finalPrice} onChange={(e) => setFinalPrice(e.target.value)} />
                    </div>
                  </div>
                </div>
              )}

              <div className="modal-footer">
                <button
                  className="secondary-btn"
                  onClick={() => {
                    if (modalStep === 'review') setModalStep('upload')
                    else setIsModalOpen(false)
                  }}
                >
                  {modalStep === 'review' ? 'Back' : 'Close'}
                </button>
                <button
                  className="primary-btn"
                  disabled={!billId || !finalPrice || uploadState !== 'done' || modalStep !== 'review'}
                  onClick={handleSaveInvestment}
                >
                  Save investment
                </button>
              </div>
            </div>
          </div>
        )}

          </div>
        </div>
      </div>
    </div>
  )
}

type CategoryCardProps = {
  title: string
  subtitle: string
  accent: 'gold' | 'diamond'
  count: number
  total: number
  onClick: () => void
}

function CategoryCard({ title, subtitle, accent, count, total, onClick }: CategoryCardProps) {
  return (
    <div className={accent === 'gold' ? 'category-card gold' : 'category-card diamond'} onClick={onClick} style={{ cursor: 'pointer' }}>
      <p className="category-title">{title}</p>
      <p className="category-subtitle">{subtitle}</p>
      <p className="category-meta">{count} bill{count !== 1 ? 's' : ''} · ₹{total.toLocaleString('en-IN')} invested</p>
    </div>
  )
}

function InvestmentList({
  title,
  investments,
  onDelete,
}: {
  title: string
  investments: SavedInvestment[]
  onDelete: (id: string) => void
}) {
  const [openMenuId, setOpenMenuId] = useState<string | null>(null)

  return (
    <section>
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', margin: '8px 0 12px' }}>
        <div>
          <h2 style={{ margin: 0 }}>{title}</h2>
          <p style={{ margin: '4px 0 0', color: '#9da1c4', fontSize: 12 }}>Your saved bills & valuations</p>
        </div>
        <button className="secondary-btn" type="button" disabled>
          See all
        </button>
      </div>
      {investments.length === 0 ? (
        <p style={{ color: '#9da1c4', fontSize: 12 }}>No investments yet.</p>
      ) : (
        <div className="inv-list">
          {investments.map((inv) => (
            (() => {
              // Best-effort per-investment mark-to-market using today's gold rates.
              // Only used for gold_jewellery rows.
              const meta = inv.metadata ?? {}
              const purity = inv.purity_karat ?? (typeof meta.goldPurity === 'string' ? parseInt(meta.goldPurity.replace(/[^0-9]/g, ''), 10) : null) ?? 24
              const w = inv.weight_grams ?? (typeof meta.netMetalWeight === 'number' ? meta.netMetalWeight : 0) ?? 0
              const rates = (window as any).__goldTodayRates as (GoldTodayResponse | null) // set in App below
              const rate = rates?.inr_per_gram?.[String(purity)] ?? rates?.inr_per_gram?.['24'] ?? null
              const currentValue = rate != null ? rate * w : null
              const invested = inv.total_amount ?? 0
              const retAmt = currentValue != null ? currentValue - invested : null
              const retPct = currentValue != null && invested > 0 ? (retAmt! / invested) * 100 : null

              return (
            <div key={inv.id} className="inv-row">
              <div className="inv-left">
                <div className="inv-avatar">Au</div>
                <div className="inv-text">
                  <div className="inv-row-title">{inv.name}</div>
                  <div className="inv-row-sub">{inv.vendor ?? '—'}</div>
                </div>
              </div>

              <div className="inv-right">
                <div className="inv-row-amount">₹{inv.total_amount.toLocaleString('en-IN')}</div>
                <div className={retAmt != null ? (retAmt >= 0 ? 'inv-row-sub green' : 'inv-row-sub red') : 'inv-row-sub'}>
                  {retAmt == null || retPct == null
                    ? (inv.date ?? '—')
                    : `${retAmt >= 0 ? '+' : ''}₹${Math.round(retAmt).toLocaleString('en-IN')} (${retPct >= 0 ? '+' : ''}${retPct.toFixed(2)}%)`}
                </div>
              </div>

              <div className="inv-menu">
                <button
                  className="inv-menu-btn"
                  onClick={() => setOpenMenuId(openMenuId === inv.id ? null : inv.id)}
                  aria-label="More actions"
                  type="button"
                >
                  ⋯
                </button>
                {openMenuId === inv.id && (
                  <div className="inv-menu-popover">
                    <button
                      className="inv-menu-item danger"
                      onClick={() => {
                        setOpenMenuId(null)
                        onDelete(inv.id)
                      }}
                      type="button"
                    >
                      Delete
                    </button>
                  </div>
                )}
              </div>
            </div>
              )
            })()
          ))}
        </div>
      )}
    </section>
  )
}

export default App
