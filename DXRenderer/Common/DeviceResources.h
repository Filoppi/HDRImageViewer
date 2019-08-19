﻿//*********************************************************
//
// Copyright (c) Microsoft. All rights reserved.
// This code is licensed under the MIT License (MIT).
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
//
//*********************************************************

#pragma once

namespace DX
{
    // Provides an interface for an application that owns DeviceResources to be notified of the device being lost or created.
    interface class IDeviceNotify
    {
        virtual void OnDeviceLost() = 0;
        virtual void OnDeviceRestored() = 0;
    };

    // Controls all the DirectX device resources.
    class DeviceResources
    {
    public:
        DeviceResources();
        void SetSwapChainPanel(Windows::UI::Xaml::Controls::SwapChainPanel^ panel);
        void SetLogicalSize(Windows::Foundation::Size logicalSize);
        void SetCurrentOrientation(Windows::Graphics::Display::DisplayOrientations currentOrientation);
        void SetDpi(float dpi);
        void SetCompositionScale(float compositionScaleX, float compositionScaleY);
        void ValidateDevice();
        void HandleDeviceLost();
        void RegisterDeviceNotify(IDeviceNotify^ deviceNotify);
        void Trim();
        void Present();

        // Device Accessors.
        Windows::Foundation::Size   GetOutputSize() const                   { return m_outputSize; }
        Windows::Foundation::Size   GetLogicalSize() const                  { return m_logicalSize; }
        float                       GetDpi() const                          { return m_dpi; }

        // D3D Accessors.
        ID3D11Device2*              GetD3DDevice() const                    { return m_d3dDevice.Get(); }
        ID3D11DeviceContext3*       GetD3DDeviceContext() const             { return m_d3dContext.Get(); }
        IDXGISwapChain3*            GetSwapChain() const                    { return m_swapChain.Get(); }
        D3D_FEATURE_LEVEL           GetDeviceFeatureLevel() const           { return m_d3dFeatureLevel; }
        ID3D11RenderTargetView*     GetBackBufferRenderTargetView() const   { return m_d3dRenderTargetView.Get(); }
        ID3D11DepthStencilView*     GetDepthStencilView() const             { return m_d3dDepthStencilView.Get(); }
        D3D11_VIEWPORT              GetScreenViewport() const               { return m_screenViewport; }
        DirectX::XMFLOAT4X4         GetOrientationTransform3D() const       { return m_orientationTransform3D; }

        // D2D Accessors.
        ID2D1Factory6*              GetD2DFactory() const                   { return m_d2dFactory.Get(); }
        ID2D1Device5*               GetD2DDevice() const                    { return m_d2dDevice.Get(); }
        ID2D1DeviceContext5*        GetD2DDeviceContext() const             { return m_d2dContext.Get(); }
        ID2D1Bitmap1*               GetD2DTargetBitmap() const              { return m_d2dTargetBitmap.Get(); }
        IDWriteFactory2*            GetDWriteFactory() const                { return m_dwriteFactory.Get(); }
        IWICImagingFactory2*        GetWicImagingFactory() const            { return m_wicFactory.Get(); }
        D2D1::Matrix3x2F            GetOrientationTransform2D() const       { return m_orientationTransform2D; }

    private:
        void CreateDeviceIndependentResources();
        void CreateDeviceResources();
        void CreateWindowSizeDependentResources();
        DXGI_MODE_ROTATION ComputeDisplayRotation();

        // Direct3D objects.
        Microsoft::WRL::ComPtr<ID3D11Device2>           m_d3dDevice;
        Microsoft::WRL::ComPtr<ID3D11DeviceContext3>    m_d3dContext;
        Microsoft::WRL::ComPtr<IDXGIFactory2>           m_dxgiFactory;
        Microsoft::WRL::ComPtr<IDXGISwapChain3>         m_swapChain;

        // Direct3D rendering objects. Required for 3D.
        Microsoft::WRL::ComPtr<ID3D11RenderTargetView>  m_d3dRenderTargetView;
        Microsoft::WRL::ComPtr<ID3D11DepthStencilView>  m_d3dDepthStencilView;
        D3D11_VIEWPORT                                  m_screenViewport;

        // Direct2D drawing components.
        Microsoft::WRL::ComPtr<ID2D1Factory6>           m_d2dFactory;
        Microsoft::WRL::ComPtr<ID2D1Device5>            m_d2dDevice;
        Microsoft::WRL::ComPtr<ID2D1DeviceContext5>     m_d2dContext;
        Microsoft::WRL::ComPtr<ID2D1Bitmap1>            m_d2dTargetBitmap;

        // DirectWrite drawing components.
        Microsoft::WRL::ComPtr<IDWriteFactory2>         m_dwriteFactory;
        Microsoft::WRL::ComPtr<IWICImagingFactory2>     m_wicFactory;

        // Cached reference to the XAML panel.
        Windows::UI::Xaml::Controls::SwapChainPanel^    m_swapChainPanel;

        // Cached device properties.
        D3D_FEATURE_LEVEL                               m_d3dFeatureLevel;
        Windows::Foundation::Size                       m_d3dRenderTargetSize;
        Windows::Foundation::Size                       m_outputSize;
        Windows::Foundation::Size                       m_logicalSize;
        Windows::Graphics::Display::DisplayOrientations m_nativeOrientation;
        Windows::Graphics::Display::DisplayOrientations m_currentOrientation;
        float                                           m_dpi;
        float                                           m_compositionScaleX;
        float                                           m_compositionScaleY;


        // Transforms used for display orientation.
        D2D1::Matrix3x2F                                m_orientationTransform2D;
        DirectX::XMFLOAT4X4                             m_orientationTransform3D;

        // The IDeviceNotify can be held directly as it owns the DeviceResources.
        IDeviceNotify^                                  m_deviceNotify;
    };
}