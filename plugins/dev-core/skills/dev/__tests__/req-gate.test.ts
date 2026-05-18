import { execSync } from 'node:child_process'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

const FIXTURE_ROOT = resolve(__dirname, 'fixtures', 'req-gate')
const SCAN = resolve(__dirname, '..', 'scan-state.sh')

function runScan(caseDir: string, extraArgs = ''): { exit: number; out: string; err: string } {
  try {
    const out = execSync(`bash ${SCAN} 42 x ${extraArgs}`, {
      cwd: resolve(FIXTURE_ROOT, caseDir),
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    })
    return { exit: 0, out, err: '' }
  } catch (e) {
    const err = e as { status?: number; stdout?: Buffer | string; stderr?: Buffer | string }
    return {
      exit: typeof err.status === 'number' ? err.status : 1,
      out: err.stdout?.toString() ?? '',
      err: err.stderr?.toString() ?? '',
    }
  }
}

describe('Σ.requirements gate (scan-state.sh)', () => {
  it.each([
    ['case-1-enabled-false', 'true', 'disabled'],
    ['case-2-req-attached', 'true', 'req-attached'],
    ['case-2b-req-attached-block-seq', 'true', 'req-attached'],
    ['case-3-marker-frame', 'true', 'frame-marker'],
    ['case-4-marker-spec', 'true', 'spec-marker'],
    ['case-5-marker-file', 'true', 'req-skipped-file'],
    ['case-6-blocked', 'false', 'not-satisfied'],
  ])('%s → requirements=%s (reason=%s)', (dir, expected, reason) => {
    const r = runScan(dir)
    expect(r.out).toMatch(new RegExp(`^requirements=${expected}$`, 'm'))
    expect(r.out).toMatch(new RegExp(`^requirements_reason=${reason}$`, 'm'))
  })

  it.each([['F-lite'], ['F-full']])('case-6 with --check-tier %s exits 2 with full BLOCK message on stderr', (tier) => {
    const r = runScan('case-6-blocked', `--check-tier ${tier}`)
    expect(r.exit).toBe(2)
    expect(r.err).toContain('step `requirements` not satisfied for issue #42')
    expect(r.err).toContain('run /req --issue 42')
    expect(r.err).toContain('check existing REQs')
  })

  it('case-1 with --check-tier F-lite does NOT exit non-zero (gate not engaged)', () => {
    const r = runScan('case-1-enabled-false', '--check-tier F-lite')
    expect(r.exit).toBe(0)
  })

  it('rejects non-integer issue numbers (defense against path-traversal and regex injection)', () => {
    try {
      execSync(`bash ${SCAN} '../etc' x`, {
        cwd: resolve(FIXTURE_ROOT, 'case-6-blocked'),
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'pipe'],
      })
      throw new Error('expected non-zero exit')
    } catch (e) {
      const err = e as { status?: number; stderr?: Buffer | string }
      expect(err.status).toBe(1)
      expect(err.stderr?.toString()).toContain('must be a positive integer')
    }
  })
})
