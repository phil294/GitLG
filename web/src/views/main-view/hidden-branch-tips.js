import { computed } from 'vue'
import { vis_v_width } from '../../data/store'
import { visible_commits } from '../../data/store/repo'
import config from '../../data/store/config'

export let use_hidden_branch_tips = () => {
	let visible_branches = computed(() => [
		...new Set(visible_commits.value.flatMap((commit) =>
			(commit.vis_lines || [])
				.map((v) => v.branch))),
	].filter(is_truthy))
	let visible_branch_tips = computed(() => [
		...new Set(visible_commits.value.flatMap((commit) =>
			commit.refs)),
	].filter((ref_) =>
		ref_ && is_branch(ref_) && ! ref_.inferred))
	let hidden_branch_tips_of_visible_branches = computed(() =>
	// alternative: (visible_commits.value[0]?.refs.filter (ref) => ref.type == 'branch' and not ref.inferred and not visible_branch_tips.value.includes(ref)) or []
		visible_branches.value.filter((branch) =>
			(! branch.inferred || config.get_boolean_or_undefined('show-inferred-quick-branch-tips')) && ! visible_branch_tips.value.includes(branch)))

	/** To paint a nice gradient between branches at the top and the vis below: */
	let fake_commit = computed(() => {
		let commit = visible_commits.value[0]
		if (! commit)
			return null
		return {
			refs: [], hash: '', hash_long: '', author_name: '', author_email: '', subject: '', index_in_graph_output: -1,
			vis_lines: commit.vis_lines
				.filter((line) => line.branch && hidden_branch_tips_of_visible_branches.value.includes(line.branch))
				.filter((line, i, all) => all.findIndex(l => l.branch === line.branch) === i) // rm duplicates
				.map((line) => {
				// This approx only works properly with curve radius 0
					let x = (line.x0 + line.xn) / 2
					return { ...line, xn: x, x0: x, xcs: x, xce: x, y0: 0, yn: 1 }
				}),
		}
	})
	// To show branch tips on top of fake_commit lines
	let branch_tip_data = computed(() => {
		let row = -1
		return [...fake_commit.value?.vis_lines || []].reverse()
			.map((line) => {
				if (! line.branch)
					return null
				row++
				if (row > 5)
					row = 0
				return {
					branch: line.branch,
					bind: {
						style: {
							left: 0 + vis_v_width.value * line.x0 + 'px',
							top: 0 + row * 19 + 'px',
						},
					},
				}
			}).filter(is_truthy) || []
	})

	return { fake_commit, branch_tip_data }
}
