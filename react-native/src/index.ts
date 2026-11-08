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
  | 'meeting-ready'
  | 'meeting-lobby'
  | 'meeting-joined'
  | 'meeting-left'
  | 'meeting-ended'
  | 'meeting-removed'
  | 'meeting-denied'
  | 'meeting-full'
  | 'meeting-missing'

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

export interface HollineMeetingOptions {
  /** Fills in the person's name, so they only tap to join. */
  name?: string
  /** Where meetings are served from. Defaults to https://holline.cloud. */
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

  /**
   * Opens a Holline meeting from its link (https://holline.cloud/m/abcd-efgh-ijkl,
   * or /a/<company>/m/… when your app opens your company's links) or its bare code.
   * Resolves false when `link` isn't a Holline meeting link. A meeting in progress
   * is never replaced.
   */
  joinMeeting(link: string, { name, baseUrl }: HollineMeetingOptions = {}): Promise<boolean> {
    return module().joinMeeting(link, name ?? null, baseUrl ?? null)
  },

  /** Whether `link` is a Holline meeting link, for routing links your app receives. */
  isMeetingLink(link: string, baseUrl?: string): Promise<boolean> {
    return module().isMeetingLink(link, baseUrl ?? null)
  },

  /** True while a call is ringing or connected, or a meeting is joined, even if the screen is hidden. */
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
