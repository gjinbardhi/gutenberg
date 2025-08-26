import { __ } from '@wordpress/i18n';
import { InspectorControls } from '@wordpress/block-editor';
import { PanelBody, RangeControl, ToggleControl } from '@wordpress/components';

export default function Edit({ attributes, setAttributes }) {
  const { postsToShow = 6, columns = 3, showExcerpt = true, showDate = true } = attributes;

  return (
    <>
      <InspectorControls>
        <PanelBody title={__('Grid Settings', 'lpg')}>
          <RangeControl
            label={__('Posts to show', 'lpg')}
            value={postsToShow}
            onChange={(v) => setAttributes({ postsToShow: v })}
            min={1} max={12}
          />
          <RangeControl
            label={__('Columns', 'lpg')}
            value={columns}
            onChange={(v) => setAttributes({ columns: v })}
            min={1} max={4}
          />
          <ToggleControl
            label={__('Show excerpt', 'lpg')}
            checked={showExcerpt}
            onChange={(v) => setAttributes({ showExcerpt: v })}
          />
          <ToggleControl
            label={__('Show date', 'lpg')}
            checked={showDate}
            onChange={(v) => setAttributes({ showDate: v })}
          />
        </PanelBody>
      </InspectorControls>

      <div className="border rounded-xl p-4">
        <p><strong>{__('Latest Posts Grid', 'lpg')}</strong></p>
        <p className="lpg-editor-note">
          {__('This block will fetch posts via /graphql on the frontend.', 'lpg')}
        </p>
      </div>
    </>
  );
}
