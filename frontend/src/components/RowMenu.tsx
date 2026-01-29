import React, { useEffect, useState } from 'react'
import { createPortal } from 'react-dom'

type Props = {
  anchorEl: HTMLElement | null
  isOpen: boolean
  onClose: () => void
  onView: () => void
  onDelete: () => void
}

export default function RowMenu({ anchorEl, isOpen, onClose, onView, onDelete }: Props) {
  const [style, setStyle] = useState<React.CSSProperties>({ display: 'none' })

  useEffect(() => {
    if (!isOpen || !anchorEl) {
      setStyle({ display: 'none' })
      return
    }

    const rect = anchorEl.getBoundingClientRect()
    const popWidth = 200 // approximate width; CSS min-width is 160
    const scrollX = window.scrollX || window.pageXOffset
    const scrollY = window.scrollY || window.pageYOffset

    let left = rect.right + scrollX - popWidth
    // keep within viewport
    const maxLeft = scrollX + window.innerWidth - 10
    const minLeft = scrollX + 8
    if (left > maxLeft) left = maxLeft
    if (left < minLeft) left = minLeft

    const top = rect.bottom + 8 + scrollY

    setStyle({ position: 'absolute', top: `${top}px`, left: `${left}px`, zIndex: 9999 })

    const onScroll = () => {
      const r = anchorEl.getBoundingClientRect()
      const sx = window.scrollX || window.pageXOffset
      const sy = window.scrollY || window.pageYOffset
      setStyle({ position: 'absolute', top: `${r.bottom + 8 + sy}px`, left: `${Math.min(Math.max(r.right + sx - popWidth, sx + 8), sx + window.innerWidth - 10)}px`, zIndex: 9999 })
    }

    window.addEventListener('scroll', onScroll, true)
    window.addEventListener('resize', onScroll)

    return () => {
      window.removeEventListener('scroll', onScroll, true)
      window.removeEventListener('resize', onScroll)
    }
  }, [isOpen, anchorEl])

  useEffect(() => {
    if (!isOpen) return
    const onDocClick = (e: MouseEvent) => {
      const target = e.target as Node
      if (!anchorEl) return
      const pop = document.getElementById('row-menu-popover')
      if (pop && (pop.contains(target) || anchorEl.contains(target))) return
      onClose()
    }
    const onEsc = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    document.addEventListener('mousedown', onDocClick)
    document.addEventListener('keydown', onEsc)
    return () => {
      document.removeEventListener('mousedown', onDocClick)
      document.removeEventListener('keydown', onEsc)
    }
  }, [isOpen, anchorEl, onClose])

  if (!isOpen) return null

  const pop = (
    <div id="row-menu-popover" className="row-menu-pop" role="menu" style={style}>
      <button className="row-menu-item" type="button" onClick={onView}>View</button>
      <button className="row-menu-item danger" type="button" onClick={onDelete}>Delete</button>
    </div>
  )

  return createPortal(pop, document.body)
}
