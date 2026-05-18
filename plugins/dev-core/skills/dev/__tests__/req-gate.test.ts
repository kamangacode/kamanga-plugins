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
    ['case-1-enabled-false', 'true'],
    ['case-2-req-attached', 'true'],
    ['case-3-marker-frame', 'true'],
    ['case-4-marker-spec', 'true'],
    ['case-5-marker-file', 'true'],
    ['case-6-blocked', 'false'],
  ])('%s → requirements=%s', (dir, expected) => {
    const r = runScan(dir)
    expect(r.out).toMatch(new RegExp(`^requirements=${expected}$`, 'm'))
  })

  it('case-6 with --check-tier F-lite exits 2 with BLOCK message on stderr', () => {
    const r = runScan('case-6-blocked', '--check-tier F-lite')
    expect(r.exit).toBe(2)
    expect(r.err).toContain('step `requirements` not satisfied for issue #42')
    expect(r.err).toContain('run /req --issue 42')
    expect(r.err).toContain('check existing REQs')
  })

  it('case-6 with --check-tier F-full also exits 2', () => {
    const r = runScan('case-6-blocked', '--check-tier F-full')
    expect(r.exit).toBe(2)
  })

  it('case-1 with --check-tier F-lite does NOT exit non-zero (gate not engaged)', () => {
    const r = runScan('case-1-enabled-false', '--check-tier F-lite')
    expect(r.exit).toBe(0)
  })
})
