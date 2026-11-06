import { NativeEventEmitter, NativeModules } from 'react-native'

export type HollinePhase =
  | 'flow'
  | 'form'
  | 'ringing'
  | 'connected'
  | 'ended'
  | 'missed'
  | 'callback'
  | 'moved'
  | 'mic-error'

export interface HollineOpenOptions {
  /** The company's slug, from its Holline call link. */
  company: string
  /** Fills in the customer's name on the form. */
  name?: string
  /** Fills in the customer's phone number on the form. */
  phone?: string
  /** Shown as the call's source in analytics. Defaults to mobile_app. */
  source?: string
  /** Where the call screen is served from. Defaults to https://holline.cloud. */
  baseUrl?: string
}

const native = NativeModules.HollineModule

function module() {
  if (!native) {
    throw new Error('Holline: the native module is missing. Rebuild the app after installing @holline/react-native.')
  }
  return native
}

let emitter: NativeEventEmitter | undefined

export const Holline = {
  /**
   * Opens the call screen, or brings back the one that's already open. A call in
   * progress is never replaced, even when the options differ.
   */
  open({ company, name, phone, source, baseUrl }: HollineOpenOptions): Promise<void> {
    return module().open(company, name ?? null, phone ?? null, source ?? null, baseUrl ?? null)
  },

  /** True while a call is ringing or connected, even if the call screen is hidden. */
  isInCall(): Promise<boolean> {
    return module().isInCall()
  },

  /** Calls `listener` when the call moves on, and returns a function that stops it. */
  onPhaseChanged(listener: (phase: HollinePhase) => void): () => void {
    emitter ??= new NativeEventEmitter(module())
    const subscription = emitter.addListener('hollinePhase', (phase) => listener(phase as unknown as HollinePhase))
    return () => subscription.remove()
  },
}
