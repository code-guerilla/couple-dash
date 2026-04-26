/// <reference types="vite/client" />

declare module 'qrcode' {
  interface QrCodeOptions {
    margin?: number
    scale?: number
    color?: {
      dark?: string
      light?: string
    }
  }

  const QRCode: {
    toDataURL(text: string, options?: QrCodeOptions): Promise<string>
  }

  export default QRCode
}
