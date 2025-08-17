<template>
	<!-- When second pane isn't shown, render only the first slot (no splitter/wrapper) -->
	<div v-if="!show_second" :class="$attrs.class">
		<slot name="first" />
	</div>
	<div v-else ref="container" class="split" :class="[orientationClass, $attrs.class]">
		<div class="pane first" :style="firstStyle">
			<slot name="first" />
		</div>
		<div
			ref="divider"
			class="divider"
			:class="orientationClass"
			role="separator"
			:aria-orientation="orientation === 'vertical' ? 'vertical' : 'horizontal'"
			:aria-label="aria_label"
			tabindex="0"
			@mousedown="onDragStart"
			@keydown="onKeyResize"
		/>
		<div class="pane second" :style="secondStyle">
			<slot name="second" />
		</div>
	</div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'

defineOptions({
	inheritAttrs: false,
})

const props = defineProps({
	// vertical: panes side-by-side, divider vertical; horizontal: panes stacked, divider horizontal
	orientation: { type: String, default: 'vertical' },
	// whether to actually render the second pane and the splitter
	show_second: { type: Boolean, default: true },
	// initial size (px) of the second pane
	initial_second: { type: Number, default: 400 },
	// min sizes in px
	min_first: { type: Number, default: 200 },
	min_second: { type: Number, default: 200 },
	// accessible label for the separator
	aria_label: { type: String, default: 'Resize panels' },
})

/** @type {import('vue').Ref<HTMLElement|null>} */
const container = ref(null)
/** @type {import('vue').Ref<HTMLElement|null>} */
const divider = ref(null)
/** @type {import('vue').Ref<number>} */
const secondSize = ref(props.initial_second) // pixels

const isVertical = computed(() => props.orientation === 'vertical')
const orientationClass = computed(() => (isVertical.value ? 'vertical' : 'horizontal'))

const firstStyle = computed(() =>
// First pane fills remaining space
	({ minWidth: isVertical.value ? props.min_first + 'px' : undefined, minHeight: ! isVertical.value ? props.min_first + 'px' : undefined }),
)

const secondStyle = computed(() => {
	const sizeProp = isVertical.value ? 'width' : 'height'
	return { [sizeProp]: secondSize.value + 'px', minWidth: isVertical.value ? props.min_second + 'px' : undefined, minHeight: ! isVertical.value ? props.min_second + 'px' : undefined, flex: '0 0 auto' }
})

let dragging = false
/** @type {number | null} */
let dragFrame = null

/** @param {MouseEvent} e */
function onDragStart(e) {
	if (! container.value)
		return
	dragging = true
	window.addEventListener('mousemove', onDrag)
	window.addEventListener('mouseup', onDragEnd)
	e.preventDefault()
}

/** @param {MouseEvent} e */
function onDrag(e) {
	if (! dragging || ! container.value)
		return
	if (dragFrame)
		cancelAnimationFrame(dragFrame)
	const rect = container.value.getBoundingClientRect()
	dragFrame = requestAnimationFrame(() => {
		if (isVertical.value) {
			// second = containerRight - mouseX
			const newSize = Math.round(rect.right - e.clientX)
			setSecondSizeClamped(newSize)
		} else {
			// second = containerBottom - mouseY
			const newSize = Math.round(rect.bottom - e.clientY)
			setSecondSizeClamped(newSize)
		}
	})
}

function onDragEnd() {
	dragging = false
	window.removeEventListener('mousemove', onDrag)
	window.removeEventListener('mouseup', onDragEnd)
}

/** @param {number} sizePx */
function setSecondSizeClamped(sizePx) {
	if (! container.value)
		return
	const rect = container.value.getBoundingClientRect()
	const total = isVertical.value ? rect.width : rect.height
	const maxSecond = Math.max(0, total - props.min_first)
	const minSecondEffective = Math.min(props.min_second, maxSecond)
	const clamped = Math.min(Math.max(sizePx, minSecondEffective), maxSecond)
	secondSize.value = clamped
}

/** @param {KeyboardEvent} e */
function onKeyResize(e) {
	const step = (e.shiftKey ? 50 : 10)
	if (isVertical.value) {
		if (e.key === 'ArrowLeft') { setSecondSizeClamped(secondSize.value + step); e.preventDefault() }
		if (e.key === 'ArrowRight') { setSecondSizeClamped(secondSize.value - step); e.preventDefault() }
	} else {
		if (e.key === 'ArrowUp') { setSecondSizeClamped(secondSize.value + step); e.preventDefault() }
		if (e.key === 'ArrowDown') { setSecondSizeClamped(secondSize.value - step); e.preventDefault() }
	}
}

// Reset size when orientation changes (optional small UX nicety)
watch(() => props.orientation, () => {
	secondSize.value = props.initial_second
})

onMounted(() => {
	// Ensure size fits on mount
	setTimeout(() => setSecondSizeClamped(secondSize.value), 0)
})

onBeforeUnmount(() => {
	if (dragging)
		onDragEnd()
})
</script>

<style scoped>
.split {
  display: flex;
  width: 100%;
  height: 100%;
  min-height: 0; /* allow children to shrink inside flex containers */
  overflow: hidden; /* prevent container scrollbars; panes handle their own */
}
.split.vertical { flex-direction: row; }
.split.horizontal { flex-direction: column; }

.pane {
  display: flex;
  min-width: 0;
  min-height: 0;
}
.pane.first { flex: 1 1 auto; }
.pane.second { overflow: hidden; min-height: 0; }

.divider {
  background: transparent;
  position: relative;
  flex: 0 0 auto;
}
.divider.vertical { width: 6px; cursor: col-resize; }
.divider.horizontal { height: 6px; cursor: row-resize; }
.divider::after {
  content: '';
  position: absolute;
  inset: 0;
  background: var(--vscode-sideBarSectionHeader-border);
  opacity: 0.6;
}
.divider:hover::after, .divider:focus-visible::after { opacity: 1; }
</style>
