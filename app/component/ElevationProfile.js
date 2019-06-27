import ceil from 'lodash/ceil';
import PropTypes from 'prop-types';
import React from 'react';
import { Scatter } from 'react-chartjs-2';

import { displayDistance } from '../util/geo-utils';

const FONT_FAMILY =
  '"Gotham Rounded SSm A", "Gotham Rounded SSm B", Arial, Georgia, Serif';

const ElevationProfile = ({ config, itinerary }) => {
  if (
    !itinerary ||
    !Array.isArray(itinerary.legs) ||
    itinerary.legs.some(leg => leg.transitLeg)
  ) {
    return null;
  }

  let cumulativeStepDistance = 0;
  const data = itinerary.legs
    .map(leg => leg.steps)
    .reduce((a, b) => [...a, ...b], [])
    .map((step, i, stepsArray) => {
      cumulativeStepDistance +=
        (stepsArray[i - 1] && stepsArray[i - 1].distance) || 0;
      return step.elevationProfile
        .filter(ep => ep.distance <= step.distance)
        .map(ep => ({
          elevation: ceil(ep.elevation, 1),
          distance: ep.distance,
          stepDistance: cumulativeStepDistance,
        }));
    })
    .reduce((a, b) => [...a, ...b], [])
    .map(point => ({
      x: ceil(point.stepDistance + point.distance, 1),
      y: point.elevation,
    }));

  if (data.length === 0) {
    return null;
  }

  const firstElement = data[0];
  if (firstElement && firstElement.x !== 0) {
    data.unshift({ x: 0, y: firstElement.y });
  }

  return (
    <div style={{ marginBottom: '1em', marginTop: '2em' }}>
      <Scatter
        data={{ datasets: [{ data, pointRadius: 0, showLine: true }] }}
        options={{
          legend: {
            display: false,
          },
          scales: {
            xAxes: [
              {
                gridLines: { display: false },
                ticks: {
                  beginAtZero: true,
                  callback: value => `${ceil(value / 1000, 1)} km`,
                  fontFamily: FONT_FAMILY,
                  max: data[data.length - 1].x,
                  maxTicksLimit: 9,
                  stepSize: 1000,
                },
                type: 'linear',
              },
            ],
            yAxes: [
              {
                gridLines: { display: false },
                ticks: {
                  callback: value => `${value} m`,
                  fontFamily: FONT_FAMILY,
                  maxTicksLimit: 4,
                  stepSize: 5,
                },
                type: 'linear',
              },
            ],
          },
          tooltips: {
            bodyFontFamily: FONT_FAMILY,
            callbacks: {
              label: ({ xLabel, yLabel }) =>
                `${ceil(yLabel, 1)} m (${
                  xLabel < 1000
                    ? `${Math.round(xLabel / 10) * 10} m`
                    : displayDistance(xLabel, config)
                })`,
            },
            displayColors: false,
            intersect: false,
            mode: 'index',
          },
        }}
        height={1}
        width={3}
      />
    </div>
  );
};

ElevationProfile.propTypes = {
  config: PropTypes.object.isRequired,
  itinerary: PropTypes.object.isRequired,
};

export default ElevationProfile;