import { useState, useEffect } from 'react'
import './App.css'

type UploadState = 'idle' | 'uploading' | 'done' | 'error'
type ModalStep = 'category' | 'upload' | 'review'

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
  hallmark_charges?: number | null
  metadata: any
}

type ActiveTab = 'home' | 'gold_list' | 'diamond_list' | 'rate_history'

type GoldTodayResponse = {
  date: string
  inr_per_gram: Record<string, number>
  source: string
  captured_at_ist?: string
}

type GoldRateHistoryItem = {
  date: string
  inr_per_gram_24k: number | null
  inr_per_gram_22k: number | null
  inr_per_gram_18k: number | null
  source?: string
  captured_at_ist?: string
}

function App() {
    // ...existing code...
  const [investments, setInvestments] = useState<SavedInvestment[]>([])
  const [activeView, setActiveView] = useState<ActiveTab>('home')
  const [goldToday, setGoldToday] = useState<GoldTodayResponse | null>(null)
  const [rateHistory, setRateHistory] = useState<GoldRateHistoryItem[]>([])
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [modalStep, setModalStep] = useState<ModalStep>('category')
  const [uploadState, setUploadState] = useState<UploadState>('idle')
  const [extractedJson, setExtractedJson] = useState<string>('')
  const [errorMessage, setErrorMessage] = useState<string>('')
  const [selectedCategory, setSelectedCategory] = useState<string>('')
  const [isAddMenuOpen, setIsAddMenuOpen] = useState(false)
  const [billId, setBillId] = useState<string | null>(null)

  const [selectedInvestment, setSelectedInvestment] = useState<SavedInvestment | null>(null)
  const [isDrawerOpen, setIsDrawerOpen] = useState(false)

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

  // Diamond-specific fields
  const [diamondCarat, setDiamondCarat] = useState('')
  const [diamondCut, setDiamondCut] = useState('')
  const [diamondClarity, setDiamondClarity] = useState('')
  const [diamondColor, setDiamondColor] = useState('')
  const [diamondCertificate, setDiamondCertificate] = useState('')

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

  const loadRateHistory = async () => {
    try {
      const res = await fetch('http://127.0.0.1:8000/rates/gold/history')
      if (res.ok) {
        const data = await res.json()
        setRateHistory(data)
      }
    } catch (err) {
      console.error('Failed to load rate history:', err)
    }
  }

  useEffect(() => {
    if (activeView === 'rate_history') {
      loadRateHistory()
    }
  }, [activeView])

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

  const openDrawer = (inv: SavedInvestment) => {
    setSelectedInvestment(inv)
    setIsDrawerOpen(true)
  }

  const closeDrawer = () => {
    setIsDrawerOpen(false)
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
    setDiamondCarat('')
    setDiamondCut('')
    setDiamondClarity('')
    setDiamondColor('')
    setDiamondCertificate('')
    // Always stay on upload step; transition to review only after processing completes
    setModalStep('upload')

    try {
      const formData = new FormData()
      formData.append('file', file)
      // Tell backend which extraction schema to use
      formData.append('category', selectedCategory === 'diamond' ? 'diamond_jewellery' : 'gold_jewellery')

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
        // Gold fields
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

        // Diamond fields (only if diamond category)
        if (selectedCategory === 'diamond') {
          if (extracted.diamondCarat != null) setDiamondCarat(String(extracted.diamondCarat))
          if (extracted.diamondCut != null) setDiamondCut(String(extracted.diamondCut))
          if (extracted.diamondClarity != null) setDiamondClarity(String(extracted.diamondClarity))
          if (extracted.diamondColor != null) setDiamondColor(String(extracted.diamondColor))
          if (extracted.diamondCertificate != null) setDiamondCertificate(String(extracted.diamondCertificate))
        }

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

  const openAddForCategory = (category: 'gold' | 'diamond') => {
    setSelectedCategory(category)
    setIsAddMenuOpen(false)
    setIsModalOpen(true)
    setModalStep('upload')
  }

  useEffect(() => {
    const onDown = (e: MouseEvent) => {
      const t = e.target as HTMLElement | null
      if (!t) return
      if (t.closest('.add-menu-wrap') || t.closest('.fab-menu') || t.closest('.fab')) return
      setIsAddMenuOpen(false)
    }
    if (isAddMenuOpen) {
      window.addEventListener('mousedown', onDown)
      return () => window.removeEventListener('mousedown', onDown)
    }
  }, [isAddMenuOpen])

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

      let payload: any = {
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
      // Only add diamond fields for diamond category
      if (selectedCategory === 'diamond') {
        payload = {
          ...payload,
          diamond_carat: toNumber(diamondCarat),
          diamond_cut: diamondCut || null,
          diamond_clarity: diamondClarity || null,
          diamond_color: diamondColor || null,
          diamond_certificate: diamondCertificate || null,
        }
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
            <button className={activeView === 'rate_history' ? 'side-nav-item active' : 'side-nav-item'} onClick={() => setActiveView('rate_history')} type="button">
              Live Rates
            </button>
          </nav>

          <div className="sidebar-foot">
            <div className="sidebar-foot-pill">
              <span className="dot" />
              Last updated 10:30 AM
            </div>
          </div>
        </aside>

        <div className="main">
          <header className="topbar">
            <div className="topbar-left">
              <div className="topbar-title">
                {activeView === 'home' ? 'Overview' : activeView === 'gold_list' ? 'Gold Jewellery' : activeView === 'diamond_list' ? 'Diamond Jewellery' : 'Live Gold Rates'}
              </div>
              <div className="topbar-sub">Clean, modern investment tracker</div>
            </div>
            <div className="topbar-right">
              {activeView !== 'home' && (
                <button className="secondary-btn" type="button" onClick={() => setActiveView('home')}>
                  Back
                </button>
              )}
            </div>
          </header>

          <div className="app-shell">

        {activeView === 'home' && (
          <>
            <div className="dash-head">
              <div>
                <p className="hero-kicker">admin / overview</p>
                <h1 className="hero-title">Portfolio dashboard</h1>
              </div>
              <div className="rate-chip">
                <span className="dot" />
                24K ₹{goldToday?.inr_per_gram?.['24']?.toLocaleString('en-IN') ?? '—'} / g
              </div>
            </div>

            <section className="stat-grid">
              <div className="stat-card">
                <div className="stat-label">Total invested</div>
                <div className="stat-value">₹{totalInvested.toLocaleString('en-IN')}</div>
              </div>
              <div className="stat-card">
                <div className="stat-label">Current gold value</div>
                <div className="stat-value">₹{Math.round(currentGoldValue).toLocaleString('en-IN')}</div>
              </div>
              <div className="stat-card">
                <div className="stat-label">Return</div>
                <div className={returnAmount >= 0 ? 'stat-value green' : 'stat-value red'}>
                  {returnAmount >= 0 ? '+' : ''}₹{Math.round(returnAmount).toLocaleString('en-IN')}
                  <span className="stat-sub">({returnPct >= 0 ? '+' : ''}{returnPct.toFixed(2)}%)</span>
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-label">XIRR</div>
                <div className={(portfolioXirr ?? 0) >= 0 ? 'stat-value green' : 'stat-value red'}>
                  {portfolioXirr == null ? '—' : `${(portfolioXirr * 100).toFixed(2)}%`}
                </div>
              </div>
            </section>

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

            <InvestmentTable
              title="Recent investments"
              investments={[...investments].slice(0, 8)}
              goldToday={goldToday}
              onView={openDrawer}
              onDelete={deleteInvestment}
            />

            {/* Floating Add button */}
            <button
              className="fab"
              onClick={() => {
                setIsAddMenuOpen((v) => !v)
              }}
            >
              <span>＋</span>
              <span>Add investment</span>
            </button>
            {isAddMenuOpen && (
              <div className="fab-menu" role="menu">
                <button className="add-menu-item" type="button" onClick={() => openAddForCategory('gold')}>
                  Gold Jewellery
                </button>
                <button className="add-menu-item" type="button" onClick={() => openAddForCategory('diamond')}>
                  Diamond Jewellery
                </button>
              </div>
            )}
          </>
        )}

        {activeView === 'gold_list' && (
          <InvestmentTable
            title="Gold Jewellery"
            investments={goldInvestments}
            goldToday={goldToday}
            onView={openDrawer}
            onDelete={deleteInvestment}
          />
        )}

        {activeView === 'diamond_list' && (
          <InvestmentTable
            title="Diamond Jewellery"
            investments={diamondInvestments}
            goldToday={goldToday}
            onView={openDrawer}
            onDelete={deleteInvestment}
          />
        )}

        {activeView === 'rate_history' && (
          <section>
            <div className="page-head">
              <div>
                <h2 className="page-title">Gold Rate History</h2>
                <p className="page-sub">Daily gold rates fetched at 10:30 AM IST</p>
              </div>
            </div>

            <div className="table-card">
              <div className="table-wrap">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Date</th>
                      <th style={{ textAlign: 'right' }}>24KT Gold (₹/g)</th>
                      <th style={{ textAlign: 'right' }}>22KT Gold (₹/g)</th>
                      <th style={{ textAlign: 'right' }}>18KT Gold (₹/g)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rateHistory.length === 0 ? (
                      <tr>
                        <td colSpan={4} className="table-empty">No rate data available.</td>
                      </tr>
                    ) : (
                      rateHistory.map((rate) => (
                        <tr key={rate.date}>
                          <td>{rate.date}</td>
                          <td style={{ textAlign: 'right' }}>
                            {rate.inr_per_gram_24k != null ? `₹${rate.inr_per_gram_24k.toLocaleString('en-IN')}` : '—'}
                          </td>
                          <td style={{ textAlign: 'right' }}>
                            {rate.inr_per_gram_22k != null ? `₹${rate.inr_per_gram_22k.toLocaleString('en-IN')}` : '—'}
                          </td>
                          <td style={{ textAlign: 'right' }}>
                            {rate.inr_per_gram_18k != null ? `₹${rate.inr_per_gram_18k.toLocaleString('en-IN')}` : '—'}
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </section>
        )}

        {isModalOpen && (
          <div className="modal-backdrop" onClick={() => setIsModalOpen(false)}>
            <div className="modal" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <p className="modal-kicker">smart add</p>
                <h2 className="modal-title">Add investment</h2>
              </div>

              {modalStep === 'category' && (
                <div className="category-select">
                  <p className="upload-title">Select investment type</p>
                  <div className="category-options">
                    <button className={selectedCategory === 'gold' ? 'toggle-btn active' : 'toggle-btn'} onClick={() => openAddForCategory('gold')}>
                      Gold Jewellery
                    </button>
                    <button className={selectedCategory === 'diamond' ? 'toggle-btn active' : 'toggle-btn'} onClick={() => openAddForCategory('diamond')}>
                      Diamond Jewellery
                    </button>
                  </div>
                </div>
              )}

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

                    {/* Diamond-specific fields */}
                    {selectedCategory === 'diamond' && (
                      <>
                        <div className="review-field">
                          <label>Diamond Carat (ct)</label>
                          <input className="field-input" value={diamondCarat || ''} onChange={e => setDiamondCarat(e.target.value)} />
                        </div>
                        <div className="review-field">
                          <label>Diamond Cut</label>
                          <input className="field-input" value={diamondCut || ''} onChange={e => setDiamondCut(e.target.value)} />
                        </div>
                        <div className="review-field">
                          <label>Diamond Clarity</label>
                          <input className="field-input" value={diamondClarity || ''} onChange={e => setDiamondClarity(e.target.value)} />
                        </div>
                        <div className="review-field">
                          <label>Diamond Color</label>
                          <input className="field-input" value={diamondColor || ''} onChange={e => setDiamondColor(e.target.value)} />
                        </div>
                        <div className="review-field">
                          <label>Certificate Number</label>
                          <input className="field-input" value={diamondCertificate || ''} onChange={e => setDiamondCertificate(e.target.value)} />
                        </div>
                      </>
                    )}

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

        {isDrawerOpen && selectedInvestment && (
          <div className="drawer-backdrop" onClick={closeDrawer}>
            <aside className="drawer" onClick={(e) => e.stopPropagation()}>
              <div className="drawer-head">
                <div>
                  <div className="drawer-title">{selectedInvestment.name}</div>
                  <div className="drawer-sub">{selectedInvestment.vendor ?? '—'} · {selectedInvestment.date ?? '—'}</div>
                </div>
                <button className="icon-btn" type="button" onClick={closeDrawer} aria-label="Close">
                  ✕
                </button>
              </div>

              <div className="drawer-kpis">
                <div className="kpi-card">
                  <div className="kpi-label">Invested</div>
                  <div className="kpi-value">₹{selectedInvestment.total_amount.toLocaleString('en-IN')}</div>
                </div>
                <div className="kpi-card">
                  <div className="kpi-label">Net weight</div>
                  <div className="kpi-value">{selectedInvestment.weight_grams ?? '—'} g</div>
                </div>
                <div className="kpi-card">
                  <div className="kpi-label">Purity</div>
                  <div className="kpi-value">{selectedInvestment.purity_karat ?? '—'}K</div>
                </div>
              </div>

              <div className="drawer-section">
                <div className="drawer-section-title">Extracted details</div>
                <pre className="drawer-pre">{JSON.stringify(selectedInvestment.metadata ?? {}, null, 2)}</pre>
              </div>

              <div className="drawer-actions">
                <button className="danger-btn" type="button" onClick={() => deleteInvestment(selectedInvestment.id)}>
                  Delete
                </button>
              </div>
            </aside>
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
  const accentColor = accent === 'gold' ? 'var(--accent)' : 'var(--accent2)'
  
  return (
    <div className={`category-card ${accent}`} onClick={onClick} style={{ cursor: 'pointer' }}>
      {/* Icon/Logo */}
      <div className="card-icon" style={{ background: `${accentColor}15` }}>
        <span className="card-icon-text">{accent === 'gold' ? '🏆' : '💎'}</span>
      </div>
      
      {/* Instrument Name */}
      <div className="card-header">
        <h3 className="card-title">{title}</h3>
      </div>
      
      {/* Price Display (Total Invested) */}
      <div className="card-price">
        <span className="price-amount">₹{(total / 100000).toFixed(2)}L</span>
        <span className="price-label">invested</span>
      </div>
      
      {/* Change Info (Count + Subtitle) */}
      <div className="card-change">
        <div className="change-item">
          <span className="change-label">{count} bills</span>
        </div>
        <div className="change-item">
          <span className="change-label change-secondary">{subtitle}</span>
        </div>
      </div>
    </div>
  )
}

function InvestmentTable({
  title,
  investments,
  goldToday,
  onView,
  onDelete,
}: {
  title: string
  investments: SavedInvestment[]
  goldToday: GoldTodayResponse | null
  onView: (inv: SavedInvestment) => void
  onDelete: (id: string) => void
}) {
  const [openMenuId, setOpenMenuId] = useState<string | null>(null)

  const computeReturn = (inv: SavedInvestment) => {
    if (!goldToday) return null
    if (inv.category !== 'gold_jewellery') return null
    const meta = inv.metadata ?? {}
    const purity = inv.purity_karat ?? (typeof meta.goldPurity === 'string' ? parseInt(meta.goldPurity.replace(/[^0-9]/g, ''), 10) : null) ?? 24
    const w = inv.weight_grams ?? (typeof meta.netMetalWeight === 'number' ? meta.netMetalWeight : 0) ?? 0
    const rate = goldToday.inr_per_gram[String(purity)] ?? goldToday.inr_per_gram['24']
    const currentValue = rate * w
    const invested = inv.total_amount ?? 0
    const retAmt = currentValue - invested
    const retPct = invested > 0 ? (retAmt / invested) * 100 : 0
    return { currentValue, retAmt, retPct }
  }

  return (
    <section>
      <div className="page-head">
        <div>
          <h2 className="page-title">{title}</h2>
          <p className="page-sub">Bills, valuations, and performance.</p>
        </div>
      </div>

      <div className="table-card">
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Item</th>
                <th>Vendor</th>
                <th>Date</th>
                <th style={{ textAlign: 'right' }}>Invested</th>
                <th style={{ textAlign: 'right' }}>Return</th>
                <th style={{ width: 80 }} />
              </tr>
            </thead>
            <tbody>
              {investments.length === 0 ? (
                <tr>
                  <td colSpan={6} className="table-empty">No investments yet.</td>
                </tr>
              ) : (
                investments.map((inv) => {
                  const r = computeReturn(inv)
                  const retText = r ? `${r.retAmt >= 0 ? '+' : ''}₹${Math.round(r.retAmt).toLocaleString('en-IN')} (${r.retPct >= 0 ? '+' : ''}${r.retPct.toFixed(2)}%)` : '—'
                  const retClass = r ? (r.retAmt >= 0 ? 'green' : 'red') : ''
                  return (
                    <tr key={inv.id}>
                      <td>
                        <button className="link-btn" type="button" onClick={() => onView(inv)}>
                          {inv.name}
                        </button>
                      </td>
                      <td>{inv.vendor ?? '—'}</td>
                      <td>{inv.date ?? '—'}</td>
                      <td style={{ textAlign: 'right' }}>₹{inv.total_amount.toLocaleString('en-IN')}</td>
                      <td style={{ textAlign: 'right' }} className={retClass}>{retText}</td>
                      <td style={{ textAlign: 'right' }}>
                        <div className="row-menu">
                          <button className="icon-btn" type="button" onClick={() => setOpenMenuId(openMenuId === inv.id ? null : inv.id)} aria-label="Row actions">
                            ⋯
                          </button>
                          {openMenuId === inv.id && (
                            <div className="row-menu-pop" role="menu">
                              <button className="row-menu-item" type="button" onClick={() => { setOpenMenuId(null); onView(inv) }}>View</button>
                              <button className="row-menu-item danger" type="button" onClick={() => { setOpenMenuId(null); onDelete(inv.id) }}>Delete</button>
                            </div>
                          )}
                        </div>
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}

export default App
