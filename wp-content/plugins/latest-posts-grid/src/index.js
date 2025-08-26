import { registerBlockType } from '@wordpress/blocks';
import { InspectorControls, useBlockProps } from '@wordpress/block-editor';
import { PanelBody, RangeControl, ToggleControl } from '@wordpress/components';
import './style.css';
import './editor.css';

const clamp = (n, min, max) => Math.max(min, Math.min(max, n ?? min));

const Edit = ({ attributes, setAttributes }) => {
  const {
    postsToShow = 4,
    columns = 3,
    showExcerpt = true,
    showDate = true,
  } = attributes;

  return (
    <div {...useBlockProps({ className: `lpg-editor cols-${columns}` })}>
      <InspectorControls>
        <PanelBody title="Grid settings" initialOpen>
          <RangeControl
            label="Posts to show"
            min={1}
            max={12}
            value={postsToShow}
            onChange={(v) => setAttributes({ postsToShow: clamp(v, 1, 12) })}
            help="Maximum 12 posts are fetched."
          />
          <RangeControl
            label="Columns"
            min={1}
            max={4}
            value={columns}
            onChange={(v) => setAttributes({ columns: clamp(v, 1, 4) })}
          />
          <ToggleControl
            label="Show excerpt"
            checked={!!showExcerpt}
            onChange={(v) => setAttributes({ showExcerpt: !!v })}
          />
          <ToggleControl
            label="Show date"
            checked={!!showDate}
            onChange={(v) => setAttributes({ showDate: !!v })}
          />
        </PanelBody>
      </InspectorControls>

      {/* Simple editor placeholder; real data is rendered on the front-end by view.js */}
      <div className="lpg-editor-placeholder">
        <p>Latest Posts Grid – preview renders on the front-end.</p>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))`,
            gap: '12px',
          }}
        >
          {Array.from({ length: Math.min(postsToShow, 4) }).map((_, i) => (
            <div
              key={i}
              style={{
                border: '1px solid #ddd',
                borderRadius: 6,
                padding: 12,
                background: '#fafafa',
              }}
            >
              <div style={{ background: '#e5e7eb', height: 120, borderRadius: 4 }} />
              <div style={{ height: 8 }} />
              <div style={{ width: '70%', height: 12, background: '#eee', borderRadius: 4 }} />
              {showDate && (
                <>
                  <div style={{ height: 8 }} />
                  <div style={{ width: '40%', height: 10, background: '#f0f0f0', borderRadius: 4 }} />
                </>
              )}
              {showExcerpt && (
                <>
                  <div style={{ height: 8 }} />
                  <div style={{ width: '100%', height: 10, background: '#f3f4f6', borderRadius: 4 }} />
                </>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

// Save emits a wrapper + data-attrs that view.js reads to fetch via WPGraphQL.
const Save = ({ attributes }) => {
  const {
    postsToShow = 4,
    columns = 3,
    showExcerpt = true,
    showDate = true,
  } = attributes;

  const data = {
    postsToShow,
    columns,
    showExcerpt,
    showDate,
  };

  return (
    <div {...useBlockProps.save({ className: `lpg-frontend cols-${columns}` })}>
      <div className="lpg-root" data-attrs={JSON.stringify(data)} />
    </div>
  );
};

registerBlockType('lpg/latest-posts-grid', {
  edit: Edit,
  save: Save,
});
