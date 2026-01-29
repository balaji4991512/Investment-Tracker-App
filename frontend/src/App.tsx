import { useState, useEffect, useRef } from 'react'
import './App.css'
import RowMenu from './components/RowMenu'

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
  inr_per_gram_14k?: number | null
  inr_per_gram_9k?: number | null
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

  const anchorRefs = useRef<Record<string, HTMLButtonElement | null>>({})

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
  const [stoneValue, setStoneValue] = useState('')  // Calculated: Gross Price - Net Metal Price
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
          // Verify data has valid inr_per_gram
          if (data && data.inr_per_gram && Object.keys(data.inr_per_gram).length > 0) {
            // Ensure 14k and 9k are populated (compute from 24k if missing)
            const r24 = data.inr_per_gram['24'] ?? data.inr_per_gram['24k'] ?? null
            const inr14 = data.inr_per_gram['14'] != null ? data.inr_per_gram['14'] : (r24 != null ? Number((r24 * 14 / 24).toFixed(2)) : null)
            const inr9 = data.inr_per_gram['9'] != null ? data.inr_per_gram['9'] : (r24 != null ? Number((r24 * 9 / 24).toFixed(2)) : null)
            data.inr_per_gram['14'] = inr14
            data.inr_per_gram['9'] = inr9
            setGoldToday(data)
            ;(window as any).__goldTodayRates = data
            console.log('[loadGold] Successfully loaded today\'s rates (normalized):', data)
          } else {
            console.warn('[loadGold] Today\'s rate data invalid, fetching fallback from history')
            const fallbackRate = await getFallbackRate()
            if (fallbackRate) {
              setGoldToday(fallbackRate)
              ;(window as any).__goldTodayRates = fallbackRate
              console.log('[loadGold] Using fallback rate:', fallbackRate)
            }
          }
        } else {
          console.warn('[loadGold] Failed to fetch today\'s rate, status:', res.status, 'fetching fallback from history')
          const fallbackRate = await getFallbackRate()
          if (fallbackRate) {
            setGoldToday(fallbackRate)
            ;(window as any).__goldTodayRates = fallbackRate
            console.log('[loadGold] Using fallback rate:', fallbackRate)
          }
        }
      } catch (err) {
        console.error('[loadGold] Failed to load gold rate:', err, 'fetching fallback from history')
        const fallbackRate = await getFallbackRate()
        if (fallbackRate) {
          setGoldToday(fallbackRate)
          ;(window as any).__goldTodayRates = fallbackRate
          console.log('[loadGold] Using fallback rate:', fallbackRate)
        }
      }
    }
    loadGold()
  }, [])

  const loadRateHistory = async () => {
    try {
      const res = await fetch('http://127.0.0.1:8000/rates/gold/history')
      if (res.ok) {
        const data = await res.json()
        // Normalize history: ensure 14k and 9k rates exist (compute from 24k if missing)
        const normalized = (data || []).map((it: any) => {
          const r24 = it.inr_per_gram_24k ?? 0
          const inr14 = it.inr_per_gram_14k != null ? it.inr_per_gram_14k : (r24 > 0 ? Number((r24 * 14 / 24).toFixed(2)) : null)
          const inr9 = it.inr_per_gram_9k != null ? it.inr_per_gram_9k : (r24 > 0 ? Number((r24 * 9 / 24).toFixed(2)) : null)
          return {
            ...it,
            inr_per_gram_24k: it.inr_per_gram_24k,
            inr_per_gram_22k: it.inr_per_gram_22k,
            inr_per_gram_18k: it.inr_per_gram_18k,
            inr_per_gram_14k: inr14,
            inr_per_gram_9k: inr9,
          } as GoldRateHistoryItem
        })
        setRateHistory(normalized)
        console.log('[loadRateHistory] Loaded history with', normalized.length, 'records')
        return normalized
      }
    } catch (err) {
      console.error('[loadRateHistory] Failed to load rate history:', err)
    }
    return []
  }
  
  // Fallback: Use last available rate from history if today's rate not available
  const getFallbackRate = async () => {
    console.log('[getFallbackRate] Fetching last available rate...')
    const history = await loadRateHistory()
    if (history && history.length > 0) {
      const lastRate = history[0]  // History is sorted descending by date
      console.log('[getFallbackRate] Using last available rate from:', lastRate.date)
      return {
        date: lastRate.date,
        inr_per_gram: {
          '24': lastRate.inr_per_gram_24k,
          '22': lastRate.inr_per_gram_22k,
          '18': lastRate.inr_per_gram_18k,
          '14': lastRate.inr_per_gram_14k ?? (lastRate.inr_per_gram_24k != null ? Number((lastRate.inr_per_gram_24k * 14 / 24).toFixed(2)) : null),
          '9': lastRate.inr_per_gram_9k ?? (lastRate.inr_per_gram_24k != null ? Number((lastRate.inr_per_gram_24k * 9 / 24).toFixed(2)) : null),
        },
        source: lastRate.source + ' (Fallback)',
      }
    }
    console.warn('[getFallbackRate] No fallback rate available')
    return null
  }

  useEffect(() => {
    if (activeView === 'rate_history') {
      loadRateHistory()
    }
  }, [activeView])

  // CATEGORY-AGNOSTIC LINE ITEM VALUATION
  // Computes Current Value for any investment regardless of category
  const computeLineItemValue = (inv: SavedInvestment): number => {
    if (!inv || !inv.total_amount) return 0
    
    const meta = inv.metadata ?? {}
    
    // GOLD JEWELLERY: Current Value = Net Metal Weight × Gold Rate
    if (inv.category === 'gold_jewellery') {
      if (!goldToday || !goldToday.inr_per_gram) return 0
      
      const purity = inv.purity_karat ?? 24
      const purityKey = String(purity)
      const rate = goldToday.inr_per_gram[purityKey] ?? goldToday.inr_per_gram['24']
      const weight = inv.weight_grams ?? (meta.netMetalWeight ?? 0)
      
      if (rate && weight > 0) {
        return rate * weight
      }
      return 0
    }
    
    // DIAMOND JEWELLERY: Current Value = Gold Value + Diamond Value
    if (inv.category === 'diamond_jewellery') {
      if (!goldToday || !goldToday.inr_per_gram) return inv.total_amount // Fallback to invested
      
      const purity = inv.purity_karat ?? 24
      const purityKey = String(purity)
      const rate = goldToday.inr_per_gram[purityKey] ?? goldToday.inr_per_gram['24']
      const weight = inv.weight_grams ?? (meta.netMetalWeight ?? 0)
      
      const goldValue = (rate && weight > 0) ? rate * weight : 0
      
      // Diamond value: Use extracted stoneCost (now properly computed by backend)
      // stoneCost should always be available after backend post-processing
      let diamondValue = 0
      if (typeof meta.stoneCost === 'number' && meta.stoneCost > 0) {
        diamondValue = meta.stoneCost
      } else {
        // Fallback: Try to compute if stoneCost not available (shouldn't happen after backend fix)
        if (typeof meta.grossPrice === 'number' && typeof meta.netMetalWeight === 'number' && typeof meta.goldRatePerGram === 'number') {
          const grossPrice = meta.grossPrice
          const netMetalPrice = meta.netMetalWeight * meta.goldRatePerGram
          diamondValue = Math.max(0, grossPrice - netMetalPrice)
        }
      }
      
      return goldValue + diamondValue
    }
    
    // UNMAPPED CATEGORY: Fallback to invested amount (valuation pending)
    console.warn(`[computeLineItemValue] Unmapped category "${inv.category}" for ${inv.name}, using invested amount as placeholder`)
    return inv.total_amount
  }

  // Compute totals (category-agnostic)
  const totalInvested = investments.reduce((sum, inv) => sum + (inv.total_amount || 0), 0)
  const totalCurrentValue = investments.reduce((sum, inv) => sum + computeLineItemValue(inv), 0)
  
  // Portfolio returns
  const returnAmount = totalCurrentValue - totalInvested
  const returnPct = totalInvested > 0 ? (returnAmount / totalInvested) * 100 : 0
  
  // Keep category-filtered arrays for sidebar navigation (still useful for filtering views)
  const goldInvestments = investments.filter(inv => inv.category === 'gold_jewellery')
  const diamondInvestments = investments.filter(inv => inv.category === 'diamond_jewellery')
  const goldTotal = goldInvestments.reduce((sum, inv) => sum + (inv.total_amount || 0), 0)
  const diamondTotal = diamondInvestments.reduce((sum, inv) => sum + (inv.total_amount || 0), 0)

  // Category-level current values and returns (for future category-level dashboard)
  // const goldReturnAmount = currentGoldValue - goldTotal
  // const goldReturnPct = goldTotal > 0 ? (goldReturnAmount / goldTotal) * 100 : 0

  // const diamondReturnAmount = currentDiamondValue - diamondTotal
  // const diamondReturnPct = diamondTotal > 0 ? (diamondReturnAmount / diamondTotal) * 100 : 0

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

  // Calculate XIRR for portfolio (date-aware using all investments and current values)
  const portfolioXirr = (() => {
    const flows: { date: Date, amount: number }[] = []
    for (const inv of investments) {
      if (!inv.date || !inv.total_amount) continue
      const d = new Date(inv.date)
      if (isNaN(d.getTime())) continue
      flows.push({ date: d, amount: -inv.total_amount })
    }
    // Need at least 2 flows (purchase + exit)
    if (flows.length === 0) return null
    // terminal cashflow = current portfolio value today
    flows.sort((a, b) => a.date.getTime() - b.date.getTime())
    flows.push({ date: new Date(), amount: totalCurrentValue })
    return computeXirr(flows)
  })()

  // Calculate category-level XIRR for Gold Jewellery (for future category-level dashboard)
  // const goldXirr = (() => {
  //   const flows: { date: Date, amount: number }[] = []
  //   for (const inv of goldInvestments) {
  //     if (!inv.date || !inv.total_amount) continue
  //     const d = new Date(inv.date)
  //     if (isNaN(d.getTime())) continue
  //     flows.push({ date: d, amount: -inv.total_amount })
  //   }
  //   if (flows.length === 0) return null
  //   flows.sort((a, b) => a.date.getTime() - b.date.getTime())
  //   flows.push({ date: new Date(), amount: currentGoldValue })
  //   return computeXirr(flows)
  // })()

  // Calculate category-level XIRR for Diamond Jewellery (for future category-level dashboard)
  // const diamondXirr = (() => {
  //   const flows: { date: Date, amount: number }[] = []
  //   for (const inv of diamondInvestments) {
  //     if (!inv.date || !inv.total_amount) continue
  //     const d = new Date(inv.date)
  //     if (isNaN(d.getTime())) continue
  //     flows.push({ date: d, amount: -inv.total_amount })
  //   }
  //   if (flows.length === 0) return null
  //   flows.sort((a, b) => a.date.getTime() - b.date.getTime())
  //   // For diamonds, current value = invested amount (no live rates)
  //   flows.push({ date: new Date(), amount: currentDiamondValue })
  //   return computeXirr(flows)
  // })()

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

  // Calculate Stone/Diamond Value = Gross Price - Net Metal Price
  const calculateStoneValue = () => {
    // Only compute stone/diamond value for Diamond jewellery. For Gold, stoneValue must not be derived.
    if (selectedCategory !== 'diamond') {
      setStoneValue('')
      return 0
    }

    const gross = parseFloat(grossPrice) || 0
    const metalWeight = parseFloat(netMetalWeight) || 0
    const rate = parseFloat(goldPrice) || 0

    // Prefer explicit stoneCost if provided by extraction
    const explicitStone = parseFloat(stoneCost) || 0
    if (explicitStone > 0) {
      setStoneValue(String(explicitStone))
      return explicitStone
    }

    // Only compute fallback stone value when we have a stone/diamond weight (carat or stone weight)
    const hasStoneWeight = (stoneWeight && String(stoneWeight).trim() !== '') || (diamondCarat && String(diamondCarat).trim() !== '')
    if (gross > 0 && metalWeight > 0 && rate > 0 && hasStoneWeight) {
      const netMetalPrice = metalWeight * rate
      const stoneVal = gross - netMetalPrice
      setStoneValue(stoneVal > 0 ? String(stoneVal.toFixed(2)) : '0')
      return stoneVal
    }

    setStoneValue('')
    return 0
  }

  // Recalculate stone/diamond value when relevant fields change (only for diamond category)
  useEffect(() => {
    calculateStoneValue()
  }, [grossPrice, netMetalWeight, goldPrice, stoneCost, selectedCategory])

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
        // Only auto-populate stone cost when it's appropriate:
        // - For diamond category: always populate if present
        // - For gold category: populate only when a stone weight (g) is present in extraction
        if (stone != null) {
          const stoneWeightPresent = stoneW != null && Number(stoneW) > 0
          if (selectedCategory === 'diamond' || (selectedCategory === 'gold' && stoneWeightPresent)) {
            setStoneCost(String(stone))
          } else {
            // do not auto-populate stone cost for gold when no stone weight/carats present
            // ensure stoneCost remains empty so UI won't show it
          }
        }
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
        // total_amount will be computed below per category rules to avoid inferred values
        total_amount: null,
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

      // Enforce pricing rules per category before sending
      const weight = toNumber(netMetalWeight) || 0
      const ratePerGram = toNumber(goldPrice) || 0
      const makingPerGram = toNumber(makingChargesPerGram) || 0
      const gstVal = toNumber(gsts) || 0
      const discountsVal = toNumber(discounts) || 0
      const explicitStone = toNumber(stoneCost) || null
      const grossVal = toNumber(grossPrice) || null

      // Clone metadata so we can add computed values without losing original extraction
      const metaCopy = metadata ? { ...metadata } : {}

      if (selectedCategory === 'gold') {
        // GOLD: If invoice Gross is present, use it directly (Gross + GST - Discounts).
        // Do NOT derive stone cost when not present; treat stone as 0 unless explicitly provided and stone weight exists.
        const hallmarkCharges = typeof metaCopy.hallmark_charges === 'number' ? metaCopy.hallmark_charges : 0
        // Prefer explicit finalPrice from extraction when available
        const finalAmountNum = toNumber(finalPrice)
        if (finalAmountNum != null) {
          payload.total_amount = finalAmountNum
          metaCopy.finalPrice = finalAmountNum
          if (explicitStone != null && explicitStone > 0) metaCopy.stoneCost = explicitStone
          metaCopy.goldRatePerGram = ratePerGram
          metaCopy.netMetalWeight = weight
        } else if (grossVal != null) {
          // Use invoice gross as authoritative when finalPrice missing
          payload.total_amount = Number((grossVal + (gstVal || 0) - (discountsVal || 0)).toFixed(2))
          metaCopy.grossPrice = grossVal
          if (explicitStone != null && explicitStone > 0) metaCopy.stoneCost = explicitStone
          metaCopy.goldRatePerGram = ratePerGram
          metaCopy.netMetalWeight = weight
        } else {
          // No invoice gross: compute from components (only when necessary)
          const stoneVal = explicitStone != null ? explicitStone : 0
          const metalValue = weight * ratePerGram
          const makingTotal = makingPerGram * weight
          const grossComputed = metalValue + makingTotal + (stoneVal || 0) + (hallmarkCharges || 0)
          const finalComputed = grossComputed + (gstVal || 0) - (discountsVal || 0)

          payload.total_amount = Number(finalComputed.toFixed(2))
          metaCopy.grossPrice = grossComputed
          if (explicitStone != null && explicitStone > 0) metaCopy.stoneCost = explicitStone
          metaCopy.goldRatePerGram = ratePerGram
          metaCopy.netMetalWeight = weight
        }
      }

      if (selectedCategory === 'diamond') {
        // DIAMOND: prefer explicit stoneCost; if absent, compute stone value = gross - metalValue when possible
        let stoneVal: number | null = explicitStone
        if ((stoneVal == null || stoneVal === 0) && grossVal != null && weight > 0 && ratePerGram > 0) {
          const metalValue = weight * ratePerGram
          stoneVal = Math.max(0, grossVal - metalValue)
        }
        if (stoneVal != null) {
          metaCopy.stoneCost = Number(stoneVal.toFixed(2))
        }
        // Ensure backend has grossPrice if available
        if (grossVal != null) metaCopy.grossPrice = grossVal
        metaCopy.goldRatePerGram = ratePerGram
        metaCopy.netMetalWeight = weight

        // If finalPrice is provided by extraction/user, prefer it; otherwise compute from gross+gst-discounts when gross available
        if (toNumber(finalPrice) != null) {
          payload.total_amount = toNumber(finalPrice)
        } else if (grossVal != null) {
          payload.total_amount = Number((grossVal + (gstVal || 0) - (discountsVal || 0)).toFixed(2))
        } else {
          payload.total_amount = null
        }
      }

      // FINAL VALIDATION: ensure Gross Price (if present in invoice) tallies with computed components
      const tolerance = 1.0 // INR tolerance
      // For gold we prefer invoice Gross when provided — no confirmation prompt needed.

      if (selectedCategory === 'diamond') {
        const metalValue = weight * ratePerGram
        if (grossVal != null) {
          // If explicit stone provided, check gross ≈ metal + stone
          if (explicitStone != null && explicitStone > 0) {
            const expectedGross = metalValue + explicitStone
            if (Math.abs(expectedGross - grossVal) > tolerance) {
              const proceed = confirm(
                `Gross Price from invoice (₹${grossVal}) does not match Metal+Stone (₹${expectedGross.toFixed(2)}).\n\n` +
                `Computed components:\n  Metal Value: ₹${metalValue.toFixed(2)}\n  Stone (explicit): ₹${explicitStone.toFixed(2)}\n\nProceed to save anyway?`
              )
              if (!proceed) return
            }
          }
          // Also check final amount consistency if finalPrice not provided
          if (toNumber(finalPrice) == null) {
            const computedFinal = Number((grossVal + (gstVal || 0) - (discountsVal || 0)).toFixed(2))
            if (payload.total_amount != null && Math.abs(payload.total_amount - computedFinal) > tolerance) {
              const proceed = confirm(
                `Computed final amount (₹${computedFinal}) differs from derived total (₹${payload.total_amount}). Proceed?`
              )
              if (!proceed) return
            }
          }
        }
      }

      // Attach sanitized metadata copy
      payload.metadata = metaCopy

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
                <div className="stat-label">Current investment value</div>
                <div className="stat-value">₹{Math.round(totalCurrentValue).toLocaleString('en-IN')}</div>
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
              anchorRefs={anchorRefs}
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
            anchorRefs={anchorRefs}
          />
        )}

        {activeView === 'diamond_list' && (
          <InvestmentTable
            title="Diamond Jewellery"
            investments={diamondInvestments}
            goldToday={goldToday}
            onView={openDrawer}
            onDelete={deleteInvestment}
            anchorRefs={anchorRefs}
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
                      <th style={{ textAlign: 'right' }}>14KT Gold (₹/g)</th>
                      <th style={{ textAlign: 'right' }}>9KT Gold (₹/g)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rateHistory.length === 0 ? (
                      <tr>
                        <td colSpan={6} className="table-empty">No rate data available.</td>
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
                          <td style={{ textAlign: 'right' }}>
                            {rate.inr_per_gram_14k != null ? `₹${rate.inr_per_gram_14k.toLocaleString('en-IN')}` : '—'}
                          </td>
                          <td style={{ textAlign: 'right' }}>
                            {rate.inr_per_gram_9k != null ? `₹${rate.inr_per_gram_9k.toLocaleString('en-IN')}` : '—'}
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
                    {/* For Gold: only show Stone Cost if it was explicitly present in extraction (do not allow deriving it) */}
                    {selectedCategory === 'gold' && stoneCost !== '' && (
                      <div className="review-field">
                        <label>Stone Cost (₹)</label>
                        <input className="field-input" value={stoneCost} onChange={(e) => setStoneCost(e.target.value)} />
                      </div>
                    )}

                    <div className="review-field">
                      <label>Gross Price (₹)</label>
                      <input className="field-input" value={grossPrice} onChange={(e) => setGrossPrice(e.target.value)} />
                    </div>

                    {/* Show Stone/Diamond Value only for Diamond jewellery (prefer explicit stoneCost if present otherwise compute) */}
                    {selectedCategory === 'diamond' && (
                      <div className="review-field">
                        <label>Stone/Diamond Value (₹)</label>
                        <input 
                          className="field-input" 
                          value={stoneValue} 
                          readOnly 
                          title="Calculated as: Gross Price - (Net Metal Weight × Gold Rate)"
                          placeholder="Auto-calculated"
                        />
                        <small style={{ fontSize: '10px', color: 'rgba(15, 23, 42, 0.6)', marginTop: '2px' }}>
                          Auto-calculated: Gross Price − (Weight × Rate) or direct Stone Cost
                        </small>
                      </div>
                    )}

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
  anchorRefs,
}: {
  title: string
  investments: SavedInvestment[]
  goldToday: GoldTodayResponse | null
  onView: (inv: SavedInvestment) => void
  onDelete: (id: string) => void
  anchorRefs: React.MutableRefObject<Record<string, HTMLButtonElement | null>>
}) {
  const [openMenuId, setOpenMenuId] = useState<string | null>(null)

  const computeReturn = (inv: SavedInvestment) => {
    if (!goldToday || !goldToday.inr_per_gram) return null
    
    const meta = inv.metadata ?? {}
    
    // GOLD JEWELLERY: Current Value = Net Metal Weight × Gold Rate
    if (inv.category === 'gold_jewellery') {
      const purity = inv.purity_karat ?? (typeof meta.goldPurity === 'string' ? parseInt(meta.goldPurity.replace(/[^0-9]/g, ''), 10) : null) ?? 24
      const weight = inv.weight_grams ?? (typeof meta.netMetalWeight === 'number' ? meta.netMetalWeight : 0) ?? 0
      const rate = goldToday.inr_per_gram[String(purity)] ?? goldToday.inr_per_gram['24']
      
      const currentValue = rate * weight
      const invested = inv.total_amount ?? 0
      const retAmt = currentValue - invested
      const retPct = invested > 0 ? (retAmt / invested) * 100 : 0
      
      if (weight === 0 || !rate) {
        console.warn(`[computeReturn] Gold ${inv.name}: weight=${weight}, purity=${purity}, rate=${rate}`)
      }
      
      return { currentValue, retAmt, retPct }
    }
    
    // DIAMOND JEWELLERY: Current Value = Gold Value + Diamond/Stone Value
    if (inv.category === 'diamond_jewellery') {
      // Calculate gold component: Net Metal Weight × Gold Rate
      const purity = inv.purity_karat ?? (typeof meta.goldPurity === 'string' ? parseInt(meta.goldPurity.replace(/[^0-9]/g, ''), 10) : null) ?? 24
      const weight = inv.weight_grams ?? (typeof meta.netMetalWeight === 'number' ? meta.netMetalWeight : 0) ?? 0
      const rate = goldToday.inr_per_gram[String(purity)] ?? goldToday.inr_per_gram['24']
      
      const goldValue = rate * weight
      
      // Calculate diamond/stone value (extracted or computed)
      let diamondValue = 0
      if (typeof meta.stoneCost === 'number' && meta.stoneCost > 0) {
        // Direct extraction
        diamondValue = meta.stoneCost
      } else if (typeof meta.grossPrice === 'number' && typeof meta.netMetalWeight === 'number' && typeof meta.goldRatePerGram === 'number') {
        // Computed: Gross Price - (Weight × Rate)
        const grossPrice = meta.grossPrice
        const netMetalPrice = meta.netMetalWeight * meta.goldRatePerGram
        diamondValue = Math.max(0, grossPrice - netMetalPrice)
      }
      
      // Total current value
      const currentValue = goldValue + diamondValue
      const invested = inv.total_amount ?? 0
      const retAmt = currentValue - invested
      const retPct = invested > 0 ? (retAmt / invested) * 100 : 0
      
      console.log(`[computeReturn] Diamond ${inv.name}: goldValue=${goldValue}, diamondValue=${diamondValue}, total=${currentValue}`)
      
      return { currentValue, retAmt, retPct }
    }
    
    return null
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
                          <button
                            className="icon-btn"
                            type="button"
                            ref={(el) => {
                              if (el) anchorRefs.current[inv.id] = el
                            }}
                            onClick={() => setOpenMenuId(openMenuId === inv.id ? null : inv.id)}
                            aria-label="Row actions"
                          >
                            ⋯
                          </button>
                          <RowMenu
                            anchorEl={anchorRefs.current[inv.id] ?? null}
                            isOpen={openMenuId === inv.id}
                            onClose={() => setOpenMenuId(null)}
                            onView={() => { setOpenMenuId(null); onView(inv) }}
                            onDelete={() => { setOpenMenuId(null); onDelete(inv.id) }}
                          />
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
