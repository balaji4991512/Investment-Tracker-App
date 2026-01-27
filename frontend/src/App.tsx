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

function App() {
  const [investments, setInvestments] = useState<SavedInvestment[]>([])
  const [activeView, setActiveView] = useState<'home' | 'gold_list' | 'diamond_list'>('home')
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

  // Compute totals
  const totalInvested = investments.reduce((sum, inv) => sum + (inv.total_amount || 0), 0)
  const goldInvestments = investments.filter(inv => inv.category === 'gold_jewellery')
  const diamondInvestments = investments.filter(inv => inv.category === 'diamond_jewellery')
  const goldTotal = goldInvestments.reduce((sum, inv) => sum + (inv.total_amount || 0), 0)
  const diamondTotal = diamondInvestments.reduce((sum, inv) => sum + (inv.total_amount || 0), 0)

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
      <div className="app-shell">
        {activeView !== 'home' && (
          <button className="secondary-btn" onClick={() => setActiveView('home')} style={{ marginBottom: 12 }}>
            Back
          </button>
        )}

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
            <button className="fab" onClick={() => { setIsModalOpen(true); setModalStep('upload') }}>
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
  return (
    <section>
      <h2 style={{ margin: '8px 0 12px' }}>{title}</h2>
      {investments.length === 0 ? (
        <p style={{ color: '#9da1c4', fontSize: 12 }}>No investments yet.</p>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {investments.map((inv) => (
            <div
              key={inv.id}
              style={{
                border: '1px solid #262a46',
                borderRadius: 14,
                padding: '12px 12px',
                background: '#090b1b',
                display: 'flex',
                justifyContent: 'space-between',
                gap: 12,
              }}
            >
              <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>{inv.name}</div>
                <div style={{ fontSize: 11, color: '#9da1c4' }}>{inv.vendor ?? '—'} · {inv.date ?? '—'}</div>
                <div style={{ fontSize: 12 }}>₹{inv.total_amount.toLocaleString('en-IN')}</div>
              </div>
              <button className="secondary-btn" onClick={() => onDelete(inv.id)}>
                Delete
              </button>
            </div>
          ))}
        </div>
      )}
    </section>
  )
}

export default App
