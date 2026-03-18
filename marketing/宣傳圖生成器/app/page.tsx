"use client";

import React, { useRef, useState, useCallback } from "react";
import { toPng } from "html-to-image";

// Constants
const IPHONE_W = 1290;
const IPHONE_H = 2796;

// App Brand Colors
const BRAND = {
  primary: "#1a73e8",
  accent: "#00bfa5",
  dark: "#0f1419",
  light: "#ffffff",
  gray: "#f8f9fa",
};

// Screenshot Definitions
const SCREENSHOTS = [
  {
    id: "slide-1",
    title: "語音記帳，一秒完成",
    subtitle: "Voice expense tracking, done in 1 second",
    gradient: `linear-gradient(135deg, ${BRAND.primary} 0%, ${BRAND.accent} 100%)`,
    textColor: BRAND.light,
    content: "slide1",
  },
  {
    id: "slide-2",
    title: "AI 智慧分類",
    subtitle: "AI Smart categorization",
    gradient: `linear-gradient(135deg, #1e3c72 0%, #2a5298 100%)`,
    textColor: BRAND.light,
    content: "slide2",
  },
  {
    id: "slide-3",
    title: "被動追蹤，不遺漏",
    subtitle: "Passive tracking, miss nothing",
    gradient: `linear-gradient(135deg, #0a0e27 0%, #1a3c55 100%)`,
    textColor: BRAND.light,
    content: "slide3",
  },
  {
    id: "slide-4",
    title: "每日金句，理財智慧",
    subtitle: "Daily quotes, financial wisdom",
    gradient: `linear-gradient(135deg, ${BRAND.primary} 0%, #3949ab 100%)`,
    textColor: BRAND.light,
    content: "slide4",
  },
  {
    id: "slide-5",
    title: "家庭共享帳本",
    subtitle: "Family shared ledger",
    gradient: `linear-gradient(135deg, #00897b 0%, #004d40 100%)`,
    textColor: BRAND.light,
    content: "slide5",
  },
];

// Screenshot Content Components
function Slide1Content() {
  return (
    <div className="absolute inset-0 flex flex-col items-center justify-center px-12">
      <div className="mb-8">
        <svg
          className="w-32 h-32 mx-auto"
          viewBox="0 0 100 100"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* Microphone icon */}
          <rect x="35" y="15" width="30" height="35" rx="15" fill="white" />
          <path
            d="M50 50C40 50 35 56 35 65V75C35 83 42 90 50 90C58 90 65 83 65 75V65C65 56 60 50 50 50Z"
            fill="white"
          />
          <line x1="50" y1="85" x2="50" y2="95" stroke="white" strokeWidth="3" />
          <line x1="35" y1="92" x2="65" y2="92" stroke="white" strokeWidth="3" />
        </svg>
      </div>
      <div className="text-center">
        <p className="text-7xl font-bold text-white mb-4">一秒完成</p>
        <p className="text-3xl text-white/90 font-light">語音自動轉帳</p>
        <p className="text-3xl text-white/90 font-light">無需手動輸入</p>
      </div>
      <div className="absolute bottom-20 left-0 right-0 flex justify-center">
        <div className="flex items-center gap-3 bg-white/20 px-8 py-4 rounded-full backdrop-blur-md">
          <div className="w-3 h-3 bg-white rounded-full animate-pulse"></div>
          <span className="text-white font-semibold">現正錄音中...</span>
        </div>
      </div>
    </div>
  );
}

function Slide2Content() {
  return (
    <div className="absolute inset-0 flex flex-col items-center justify-center px-12">
      <div className="mb-12">
        <svg
          className="w-28 h-28 mx-auto"
          viewBox="0 0 100 100"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* Chart/Category icon */}
          <rect x="15" y="60" width="15" height="30" fill="white" />
          <rect x="40" y="40" width="15" height="50" fill="white" />
          <rect x="65" y="20" width="15" height="70" fill="white" />
        </svg>
      </div>
      <p className="text-6xl font-bold text-white mb-8 text-center">
        智慧自動分類
      </p>
      <div className="space-y-4 w-full max-w-sm">
        <CategoryPill icon="🍔" label="飲食" amount="$450" />
        <CategoryPill icon="🚗" label="交通" amount="$280" />
        <CategoryPill icon="🏪" label="購物" amount="$620" />
        <CategoryPill icon="💊" label="醫療" amount="$120" />
      </div>
    </div>
  );
}

function CategoryPill({
  icon,
  label,
  amount,
}: {
  icon: string;
  label: string;
  amount: string;
}) {
  return (
    <div className="flex items-center justify-between bg-white/15 rounded-2xl px-6 py-4 backdrop-blur-sm border border-white/10">
      <div className="flex items-center gap-4">
        <span className="text-4xl">{icon}</span>
        <span className="text-2xl text-white font-semibold">{label}</span>
      </div>
      <span className="text-2xl font-bold text-white">{amount}</span>
    </div>
  );
}

function Slide3Content() {
  return (
    <div className="absolute inset-0 flex flex-col items-center justify-center px-12">
      <div className="mb-12">
        <svg
          className="w-32 h-32 mx-auto"
          viewBox="0 0 100 100"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* GPS/Map icon */}
          <circle cx="50" cy="50" r="35" fill="none" stroke="white" strokeWidth="2" />
          <circle cx="50" cy="50" r="8" fill="white" />
          <path
            d="M50 15C35 30 28 40 28 50C28 64 38 75 50 75C62 75 72 64 72 50C72 40 65 30 50 15Z"
            fill="none"
            stroke="white"
            strokeWidth="2"
          />
        </svg>
      </div>
      <p className="text-5xl font-bold text-white mb-4 text-center">
        被動追蹤
      </p>
      <p className="text-4xl text-white/90 mb-12 text-center">
        一個都不遺漏
      </p>
      <div className="space-y-3 w-full">
        <LocationItem location="全家便利商店" time="2:15 PM" />
        <LocationItem location="信義威秀影城" time="4:45 PM" />
        <LocationItem location="信義區美食街" time="6:30 PM" />
      </div>
    </div>
  );
}

function LocationItem({ location, time }: { location: string; time: string }) {
  return (
    <div className="flex items-center justify-between bg-white/10 rounded-xl px-5 py-3 backdrop-blur-sm border border-white/5">
      <span className="text-xl text-white font-medium">📍 {location}</span>
      <span className="text-lg text-white/70">{time}</span>
    </div>
  );
}

function Slide4Content() {
  return (
    <div className="absolute inset-0 flex flex-col items-center justify-center px-12">
      <div className="mb-8 flex justify-center">
        <div className="text-8xl">💡</div>
      </div>
      <div className="text-center">
        <p className="text-3xl text-white/90 mb-6 leading-relaxed font-light italic">
          "每一塊錢都是種子，
        </p>
        <p className="text-3xl text-white/90 mb-12 leading-relaxed font-light italic">
          只需澆水、耐心等候，
        </p>
        <p className="text-3xl text-white/90 leading-relaxed font-light italic">
          就會長成參天大樹。"
        </p>
        <p className="text-2xl text-white/60 mt-8">— 財經智慧語錄</p>
      </div>
    </div>
  );
}

function Slide5Content() {
  return (
    <div className="absolute inset-0 flex flex-col items-center justify-center px-12">
      <div className="mb-12">
        <svg
          className="w-32 h-32 mx-auto"
          viewBox="0 0 100 100"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* Family/People icon */}
          <circle cx="50" cy="25" r="12" fill="white" />
          <path d="M35 40C35 32 42 28 50 28C58 28 65 32 65 40" fill="white" />
          <circle cx="30" cy="55" r="10" fill="white" />
          <path d="M18 68C18 62 23 58 30 58C37 58 42 62 42 68" fill="white" />
          <circle cx="70" cy="55" r="10" fill="white" />
          <path d="M58 68C58 62 63 58 70 58C77 58 82 62 82 68" fill="white" />
        </svg>
      </div>
      <p className="text-5xl font-bold text-white mb-2 text-center">
        與家人共享
      </p>
      <p className="text-4xl text-white/90 mb-12 text-center">
        帳本一起管理
      </p>
      <div className="space-y-4 w-full">
        <FamilyMember name="你" expense="NT$3,250" role="管理員" />
        <FamilyMember name="老婆" expense="NT$1,890" role="成員" />
        <FamilyMember name="媽媽" expense="NT$520" role="成員" />
      </div>
    </div>
  );
}

function FamilyMember({
  name,
  expense,
  role,
}: {
  name: string;
  expense: string;
  role: string;
}) {
  return (
    <div className="flex items-center justify-between bg-white/10 rounded-2xl px-6 py-4 backdrop-blur-sm border border-white/10">
      <div className="flex items-center gap-4">
        <div className="w-14 h-14 bg-white/30 rounded-full flex items-center justify-center">
          <span className="text-2xl">👤</span>
        </div>
        <div>
          <p className="text-2xl font-semibold text-white">{name}</p>
          <p className="text-lg text-white/60">{role}</p>
        </div>
      </div>
      <div className="text-right">
        <p className="text-2xl font-bold text-white">{expense}</p>
      </div>
    </div>
  );
}

// Main Screenshot Component
function Screenshot({
  screenshot,
}: {
  screenshot: (typeof SCREENSHOTS)[0];
}) {
  const screenRef = useRef<HTMLDivElement>(null);

  const renderContent = () => {
    switch (screenshot.content) {
      case "slide1":
        return <Slide1Content />;
      case "slide2":
        return <Slide2Content />;
      case "slide3":
        return <Slide3Content />;
      case "slide4":
        return <Slide4Content />;
      case "slide5":
        return <Slide5Content />;
      default:
        return null;
    }
  };

  return (
    <div
      ref={screenRef}
      id={screenshot.id}
      style={{
        width: IPHONE_W,
        height: IPHONE_H,
        background: screenshot.gradient,
        position: "relative",
        overflow: "hidden",
        fontFamily: "Inter, system-ui, sans-serif",
        color: screenshot.textColor,
      }}
      className="relative"
    >
      {/* Header with status bar */}
      <div className="absolute top-0 left-0 right-0 h-12 bg-black/10 flex items-center justify-between px-8 text-white text-xs font-semibold">
        <span>9:41</span>
        <span>語記</span>
        <span>📶</span>
      </div>

      {/* Content */}
      {renderContent()}

      {/* Title Section */}
      <div className="absolute bottom-0 left-0 right-0 h-48 bg-gradient-to-t from-black/40 to-transparent flex flex-col items-center justify-end pb-12 px-8 text-center">
        <h1 className="text-6xl font-bold text-white mb-2 leading-tight">
          {screenshot.title}
        </h1>
        <p className="text-2xl text-white/80">{screenshot.subtitle}</p>
      </div>
    </div>
  );
}

// Main Page Component
export default function ScreenshotPage() {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [exporting, setExporting] = useState(false);

  const handleExport = useCallback(async (index: number) => {
    setExporting(true);
    try {
      const element = document.getElementById(SCREENSHOTS[index].id);
      if (!element) return;

      // Double-call trick for clean fonts
      await toPng(element as HTMLDivElement, {
        width: IPHONE_W,
        height: IPHONE_H,
        pixelRatio: 2,
        cacheBust: true,
      });

      // Second call for actual export
      const dataUrl = await toPng(element as HTMLDivElement, {
        width: IPHONE_W,
        height: IPHONE_H,
        pixelRatio: 2,
        cacheBust: true,
      });

      // Create download link
      const link = document.createElement("a");
      link.href = dataUrl;
      const filename = `語記_宣傳圖_${String(index + 1).padStart(2, "0")}_${SCREENSHOTS[index].title.replace(/\s+/g, "")}_1290x2796.png`;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      alert(`✓ 已下載: ${filename}`);
    } catch (error) {
      console.error("Export failed:", error);
      alert("匯出失敗，請重試");
    } finally {
      setExporting(false);
    }
  }, []);

  const handleExportAll = useCallback(async () => {
    setExporting(true);
    try {
      for (let i = 0; i < SCREENSHOTS.length; i++) {
        const element = document.getElementById(SCREENSHOTS[i].id);
        if (!element) continue;

        // Double-call trick
        await toPng(element as HTMLDivElement, {
          width: IPHONE_W,
          height: IPHONE_H,
          pixelRatio: 2,
          cacheBust: true,
        });

        const dataUrl = await toPng(element as HTMLDivElement, {
          width: IPHONE_W,
          height: IPHONE_H,
          pixelRatio: 2,
          cacheBust: true,
        });

        const link = document.createElement("a");
        link.href = dataUrl;
        const filename = `語記_宣傳圖_${String(i + 1).padStart(2, "0")}_${SCREENSHOTS[i].title.replace(/\s+/g, "")}_1290x2796.png`;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        // Small delay between downloads
        await new Promise((resolve) => setTimeout(resolve, 300));
      }
      alert("✓ 所有圖片已下載完成！");
    } catch (error) {
      console.error("Export all failed:", error);
      alert("全量匯出失敗，請重試");
    } finally {
      setExporting(false);
    }
  }, []);

  return (
    <div className="bg-gray-50 min-h-screen p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">
            語記 VoiceLedger - App Store 宣傳圖
          </h1>
          <p className="text-lg text-gray-600">
            5 張高品質推廣截圖 • iPhone 6.7" (1290×2796 像素)
          </p>
        </div>

        {/* Controls */}
        <div className="mb-8 flex flex-wrap gap-4">
          <button
            onClick={() => handleExport(selectedIndex)}
            disabled={exporting}
            className="bg-blue-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-700 disabled:bg-gray-400"
          >
            {exporting ? "正在匯出..." : "下載當前圖片"}
          </button>
          <button
            onClick={handleExportAll}
            disabled={exporting}
            className="bg-green-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-green-700 disabled:bg-gray-400"
          >
            {exporting ? "正在匯出..." : "下載全部 (5 張)"}
          </button>
        </div>

        {/* Navigation Tabs */}
        <div className="mb-8 flex flex-wrap gap-2 bg-white p-4 rounded-lg shadow">
          {SCREENSHOTS.map((screenshot, index) => (
            <button
              key={index}
              onClick={() => setSelectedIndex(index)}
              className={`px-4 py-2 rounded-lg font-semibold transition-all ${
                selectedIndex === index
                  ? "bg-blue-600 text-white"
                  : "bg-gray-200 text-gray-700 hover:bg-gray-300"
              }`}
            >
              圖 {index + 1}: {screenshot.title}
            </button>
          ))}
        </div>

        {/* Preview Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Main Preview */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg shadow-lg p-8 flex justify-center">
              <div
                className="border-4 border-gray-300 rounded-3xl overflow-hidden shadow-2xl"
                style={{
                  width: "360px",
                  aspectRatio: `${IPHONE_W}/${IPHONE_H}`,
                }}
              >
                <Screenshot screenshot={SCREENSHOTS[selectedIndex]} />
              </div>
            </div>
          </div>

          {/* Thumbnails */}
          <div className="lg:col-span-2">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              所有截圖
            </h2>
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
              {SCREENSHOTS.map((screenshot, index) => (
                <button
                  key={index}
                  onClick={() => setSelectedIndex(index)}
                  className={`rounded-lg overflow-hidden shadow-md hover:shadow-lg transition-all border-4 ${
                    selectedIndex === index
                      ? "border-blue-600"
                      : "border-gray-200"
                  }`}
                >
                  <div
                    className="w-full aspect-square flex items-center justify-center p-2 text-center"
                    style={{ background: screenshot.gradient }}
                  >
                    <div className="text-white">
                      <div className="text-lg font-bold">圖 {index + 1}</div>
                      <div className="text-xs mt-1">
                        {screenshot.title}
                      </div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Info Section */}
        <div className="mt-12 bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 className="text-lg font-semibold text-blue-900 mb-3">
            📋 使用說明
          </h3>
          <ul className="text-blue-800 space-y-2">
            <li>
              ✓ 每張圖片解析度: 1290×2796 像素 (iPhone 6.7" App Store 標準)
            </li>
            <li>✓ 按鈕「下載當前圖片」下載單張高解析度圖片</li>
            <li>✓ 按鈕「下載全部」依序下載所有 5 張推廣圖</li>
            <li>
              ✓ 所有圖片均已優化，可直接上傳至 Apple App Store
            </li>
            <li>
              ✓ 圖片將存至瀏覽器預設下載資料夾，檔名以 zh-TW 文字命名
            </li>
          </ul>
        </div>

        {/* Hidden Screenshots for Export */}
        <div
          style={{
            position: "fixed",
            left: "-9999px",
            top: 0,
            width: IPHONE_W,
            height: IPHONE_H * SCREENSHOTS.length,
          }}
        >
          {SCREENSHOTS.map((screenshot) => (
            <Screenshot key={screenshot.id} screenshot={screenshot} />
          ))}
        </div>
      </div>
    </div>
  );
}
