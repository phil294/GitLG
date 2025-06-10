declare module '@vue/runtime-core' {
    export interface ComponentCustomProps {
        [key: `data${string}`]: any
    }
}

export default {}