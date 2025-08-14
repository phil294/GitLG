declare module '@vue/runtime-core' {
  interface ComponentCustomProps {
    // History
    onCommit_clicked?: (hash: string) => void

    // SearchInput
    onJump_to_commit?: (commit: any) => void

    // AllBranches
    onBranch_selected?: (branch: any) => void

    // CommitDetails
    onHash_clicked?: (hash: string) => void

    // Popup
    onClose?: () => void

    // GitInput
    onExecuted?: () => void
    onSuccess?: (result?: any) => void

    // CommitRow
    onClick?: (commit: any, event: MouseEvent) => void
  }
}

export {}
