/**
 * Holds a rotating word's slot at the width of its longest option, so the
 * words around it never reflow as it changes. Invisible copies of every
 * option share one grid cell with the live word; `sizerClass` gives them the
 * same padding as the live word.
 */
export default function Reserve({ texts, sizerClass = '', children }) {
  return (
    <span className="reserve">
      {texts.map((t) => (
        <span key={t} className={`reserve-sizer ${sizerClass}`} aria-hidden="true">{t}</span>
      ))}
      <span className="reserve-live">{children}</span>
    </span>
  );
}
