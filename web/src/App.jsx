import React, { useState, useEffect, useRef, useCallback } from 'react';
import { fetchNui } from './nui.js';

const INITIAL_COLOR = '#48ff4e';
const CANCEL_COLOR = '#ff0000';
const DEFAULT_DURATION = 10000;
const DEFAULT_PERCENT = 50;

const ProgressBarFill = ({ percent, duration, color, animationKey }) => {
  const transition = percent > 0 ? `width ${duration}ms linear` : 'none';
  const boxShadow = `0 0 15px ${color}cc, 0 0 5px rgba(255, 255, 255, 0.3)`;

  return (
    <div
      key={animationKey}
      className="progressbar-fill"
      style={{ width: `${percent}%`, transition, backgroundColor: color, boxShadow }}
    />
  );
};

const ProgressBar = ({ label, percent, duration, color, animationKey }) => (
  <div className="progressbar-wrapper">
    <ProgressBarFill
      percent={percent}
      duration={duration}
      color={color}
      animationKey={animationKey}
    />
  </div>
);

const useNuiProgress = (isBrowser) => {
  const [isVisible, setIsVisible] = useState(isBrowser);
  const [label, setLabel] = useState(isBrowser ? 'Dev: Processing...' : '');
  const [duration, setDuration] = useState(isBrowser ? DEFAULT_DURATION : 0);
  const [animationKey, setAnimationKey] = useState(0);
  const [percent, setPercent] = useState(isBrowser ? DEFAULT_PERCENT : 0);
  const [color, setColor] = useState(INITIAL_COLOR);

  const animationTimeoutRef = useRef(null);
  const timerRef = useRef(null);

  const clearAllTimeouts = useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
    if (animationTimeoutRef.current) {
      clearTimeout(animationTimeoutRef.current);
      animationTimeoutRef.current = null;
    }
  }, []);

  const startProgress = useCallback((newLabel, newDuration) => {
    clearAllTimeouts();

    setColor(INITIAL_COLOR);
    setIsVisible(true);
    setLabel(newLabel);
    setDuration(newDuration);
    setAnimationKey(prev => prev + 1);
    setPercent(0);

    timerRef.current = setTimeout(() => setPercent(100), 50);

    animationTimeoutRef.current = setTimeout(() => {
      setIsVisible(false);
      fetchNui('finished', {}).catch(error =>
        console.error('Error sending finished callback:', error)
      );
    }, newDuration);
  }, [clearAllTimeouts]);

  const cancelProgress = useCallback(() => {
    clearAllTimeouts();

    const cancelSlideDuration = 200;
    setDuration(cancelSlideDuration);
    setPercent(99);
    fetchNui('cancelled', {});

    animationTimeoutRef.current = setTimeout(() => {
      setColor(CANCEL_COLOR);
      animationTimeoutRef.current = setTimeout(() => {
        setIsVisible(false);
      }, 200);
    }, cancelSlideDuration);
  }, [clearAllTimeouts]);

  useEffect(() => {
    const handleNuiMessage = (event) => {
      const { type, label, duration: newDuration } = event.data;

      if (type === 'progressbar:start') {
        startProgress(label, newDuration);
      } else if (type === 'progressbar:cancel') {
        cancelProgress();
      }
    };

    window.addEventListener('message', handleNuiMessage);

    if (isBrowser) {
      window.mockNui = (type, data = {}) => {
        window.postMessage({ type, ...data }, '*');
      };
    }

    return () => {
      window.removeEventListener('message', handleNuiMessage);

      if (isBrowser) {
        delete window.mockNui;
      }

      clearAllTimeouts();
    };
  }, [isBrowser, startProgress, cancelProgress, clearAllTimeouts]);

  return { isVisible, label, percent, duration, color, animationKey };
};

const App = () => {
  const isBrowser = !window.GetParentResourceName;
  const { isVisible, label, percent, duration, color, animationKey } = useNuiProgress(isBrowser);

  return (
    <div className={`progressbar-container ${isVisible ? 'visible' : 'hidden'}`}>
      <div className="progressbar-label">{label}</div>
      <ProgressBar
        label={label}
        percent={percent}
        duration={duration}
        color={color}
        animationKey={animationKey}
      />
    </div>
  );
};

export default App;