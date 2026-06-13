const getResourceName = () => {
  if (typeof window.GetParentResourceName === 'function') {
    return window.GetParentResourceName();
  }
  return 'filo_progressbar';
};

const isNuiEnvironment = () => typeof window.GetParentResourceName === 'function';

export async function fetchNui(eventName, data = {}) {
  if (!isNuiEnvironment()) {
    console.warn(`[NUI Mock] fetchNui called for event: ${eventName}`, data);
    return { status: 'ok' };
  }

  const resourceName = getResourceName();
  const url = `https://${resourceName}/${eventName}`;

  const options = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
  };

  const resp = await fetch(url, options);
  return resp.json();
}