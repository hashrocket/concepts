import React from 'react';

import renderer from 'react-test-renderer';

import App from '../App';

it('renders the concepts', () => {
  const concepts = [
    {
      title: 'Shapedrawer',
      author: 'chriserin',
      created_at: '2011-06-29T17:11:36Z',
      full_name: 'Chris Erin',
      description: 'This started out as an experiment.',
      languages: ['Ruby', 'JavaScript', 'CoffeeScript'],
      screenshot_url: 'images/shapedrawer.1552425047.png',
      hrcpt_url: 'https://shapedrawer.hrcpt.online',
      author_url: 'https://github.com/chriserin',
      github_url: 'https://github.com/chriserin/ShapeDrawer',
      is_heroku: true,
    },
    {
      title: 'Ceramic Nation',
      author: 'jwworth',
      created_at: '2015-09-11T05:37:54Z',
      full_name: 'Jake Worth',
      description: 'Ceramic Nation is an autogenerated novel.',
      languages: ['Ruby', 'JavaScript'],
      screenshot_url: 'images/ceramic-nation.1552491967.png',
      hrcpt_url: 'https://ceramic-nation.hrcpt.online',
      author_url: 'https://github.com/jwworth',
      github_url: 'https://github.com/jwworth/novel',
      is_heroku: true,
    },
    {
      title: 'Virtuoso',
      author: 'rpmessner',
      created_at: '2017-05-06T02:58:43Z',
      full_name: 'Ryan Messner',
      description:
        'Translate chord names to finger positions on a guitar fretboard',
      languages: ['JavaScript'],
      screenshot_url: 'images/virtuoso.1552490092.png',
      hrcpt_url: 'https://virtuoso.hrcpt.online',
      author_url: 'https://github.com/rpmessner',
      github_url: 'https://github.com/rpmessner/virtuoso',
      is_heroku: false,
    },
  ];

  const tree = renderer.create(<App concepts={concepts} />).toJSON();
  expect(tree).toMatchSnapshot();
});