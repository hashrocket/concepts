import React, { Component, Fragment, useState, useEffect, useRef } from 'react';
import styled, { css, keyframes } from 'styled-components';
import reverse from 'lodash/reverse';
import sortBy from 'lodash/sortBy';

import { colors } from './colors.js';
import conceptsHeader from './concepts-header.svg';
import downCaret from './down-caret.svg';
import githubLogo from './github-logo.svg';
import hashrocketHeader from './hashrocket-header.svg';
import herokuLogo from './heroku-logo.svg';

const sizes = {
  desktop: 992,
  tablet: 768,
  phone: 576,
};

// Iterate through the sizes and create a media template
const media = Object.keys(sizes).reduce((acc, label) => {
  acc[label] = (...args) => css`
    @media (max-width: ${sizes[label] / 16}em) {
      ${css(...args)};
    }
  `;

  return acc;
}, {});

const ApplicationContainer = styled.div`
  background-color: ${colors.backgroundGrey};
  padding-bottom: 100px;

  a {
    text-decoration: none;
    color: inherit;

    &:hover {
      color: inherit;
    }
  }
`;

const Tagline = styled.div`
  font-family: Sarala;
  font-weight: 700;
  font-size: 19px;
  color: ${colors.dark};
  letter-spacing: 0.9px;
  text-align: left;

  text-decoration: none !important;

  ${media.phone`font-size: 14px;`};
`;

const Header = styled.header`
  margin: 24px auto 0px;
  width: 400px;
  ${media.phone`width: 300px;`};
`;

const HashrocketLogo = styled.div``;

const logoPhoneMediaQuery = media.phone`
  img {
    width: 300px;
  }
`;

const ConceptsLogo = styled.div`
  margin: 15px 0 8px;
  ${logoPhoneMediaQuery};
`;

const ConceptsContainer = styled.div`
  display: grid;
  max-width: 1060px;
  margin: 30px auto 0;
  grid-template-columns: repeat(auto-fill, minmax(295px, 1fr));
  grid-gap: 42px;
  transition: all 0.3s ease-in;
  width: 90%;
  justify-items: center;
`;

const ConceptContainer = styled.div`
  transition: max-height 0.3s ease-in;
  min-height: 250px;
  width: 295px;
  margin: 10px;
  max-height: ${({ open }) => (open ? '529px' : '250px')};
  background-color: white;
  position: relative;
  background: #ffffff;
  box-shadow: 1px 1px 7px 1px rgba(199, 199, 199, 0.5);
`;

const Screenshot = styled.div`
  background-image: url('${props => '/' + props.coverImage}');
  background-size:     cover;
  background-repeat:   no-repeat;
  background-position: center center;
  width: 100%;
  height: 166px;

  :hover {
    background-image: url('${props => '/' + props.screenshotPath}');
  }
`;

const ImgFilter = styled.div`
  background: rgba(139, 139, 151, 0.44);
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 166px;
`;

const HerokuBanner = styled.div`
  background: white;
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 166px;
  font-family: Sarala;
  font-weight: 700;
  line-height: 20px;
  letter-spacing: 0.9px;
  opacity: ${({ open }) => (open ? '100' : '0')};
  z-index: ${({ open }) => (open ? '100' : '-10')};
  cursor: cursor;
  transition: opacity 0.2s ease-in;
`;

const HerokuContainer = styled.div`
  max-width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: space-evenly;
  align-items: center;
  height: 108px;
  text-align: center;
  padding: 8px;
  @keyframes spinner {
    to {
      transform: rotate(360deg);
    }
  }
`;

const HerokuSpinner = styled.div`
  width: 26px;
  height: 26px;
  border-radius: 20px;
  background-image: radial-gradient(50% 100%, #fff 0%, #6762a6 100%);
  position: relative;
  animation: spinner 1.6s linear infinite;
`;

const HerokuSpinnerMiddle = styled.div`
  background-color: white;
  position: absolute;
  border-radius: 20px;
  top: 3px;
  left: 3px;
  width: 20px;
  height: 20px;
`;

const Title = styled.div`
  background-color: #af1f24;
  font-family: Saira;
  font-weight: 700;
  font-size: 23px;
  color: #ffffff;
  letter-spacing: 1.09px;
  text-align: left;
  position: absolute;
  top: 124px;
  left: -12px;
  padding: 0 10px;
  z-index: 1000;
`;

const HigherTitle = styled(Title)`
  top: 82px;
`;

const AuthorLine = styled.div`
  margin-top: 10px;
  padding: 0 10px;
  display: flex;
  justify-content: space-between;
`;

const Author = styled.div`
  font-family: Sarala;
  font-weight: 700;
  font-size: 18px;
  color: #232326;
  letter-spacing: 0.85px;
  text-align: left;
  display: inline-block;
  white-space: nowrap;

  &:hover {
    text-decoration: underline;
  }
`;

const GithubLogo = styled.img`
  display: inline-block;
  width: 25px;
  height: 25px;
  text-align: right;
`;

const TechsLine = styled.div`
  margin-top: 8px;
  padding: 0 10px;
  display: flex;
  justify-content: space-between;
  font-family: Sarala;
  font-weight: 400;
  font-size: 14px;
  color: #000000;
  letter-spacing: 1.35px;
  text-align: left;
`;

const DownCaret = styled.img`
  cursor: pointer;
  transition: all 0.3s ease-in;
  margin-right: 7px;
  transform: ${props => (props.descriptionOpen ? 'rotate(0.5turn);' : 'none')};
`;

const Tech = styled.span`
  cursor: pointer;
  transition: all 0.3s ease-in;
  background-color: ${({ selected }) =>
    selected ? 'rgba(255,41,49,0.32)' : 'inherit'};

  &:first-child {
    margin-left: -3px;
  }

  padding-left: 3px;
  padding-right: 3px;

  &:hover {
    text-decoration: underline;
  }
`;

const Techs = props => {
  const lastTech = (index, techsLength) => index === techsLength;

  const techs = props.techs.map((tech, index) => (
    <Fragment key={tech}>
      <Tech
        onClick={() => props.selectTech(tech)}
        selected={props.selectedTech === tech}
      >
        {tech}
      </Tech>
      {lastTech(index, props.techs.length - 1) ? null : <span>•</span>}
    </Fragment>
  ));

  return <div>{techs}</div>;
};

const expandKeyframes = keyframes`
  from {
    max-height: 0;
    line-height: 1px;
    font-size: 1px;
    opacity: 0;
  }

  to {
    max-height: 320px;
    line-height: inherit;
    font-size: inherit;
    opacity: 1;
  }
`;

const AnimateParagraph = styled.p`
  padding: 0px 20px 0px 10px;
  animation: ${expandKeyframes} 0.3s ease-in;
`;

const DeAnimateParagraph = styled.p`
  padding: 0px 20px 0px 10px;
  opacity: 0;
  animation: ${expandKeyframes} 0.3s ease-in;
  animation-direction: reverse;
`;

const DescriptionContainer = styled.div`
  font-family: 'EB Garamond';
  font-weight: 400;
  font-size: 14px;
  color: #000000;
  letter-spacing: 1.15px;
  text-align: left;
  line-height: 22px;
`;

const Description = ({ open, description, container, setIsAnimating }) => {
  useEffect(
    () => {
      const fn = () => setIsAnimating(open);
      setTimeout(fn, 300);
    },
    [open]
  );

  return (
    <DescriptionContainer open={open}>
      {open ? (
        <AnimateParagraph ref={container}>{description}</AnimateParagraph>
      ) : (
        <DeAnimateParagraph ref={container}>{description}</DeAnimateParagraph>
      )}
    </DescriptionContainer>
  );
};

const InfoArea = props => {
  const container = useRef(null);
  const [isAnimating, setIsAnimating] = useState(false);

  return (
    <div>
      <AuthorLine>
        <Author>
          <a href={props.authorUrl}>by {props.author}</a>
        </Author>
        <a href={props.githubUrl}>
          <GithubLogo src={githubLogo} alt={`${props.title} Github`} />
        </a>
      </AuthorLine>
      <TechsLine>
        <Techs
          techs={props.techs}
          selectTech={props.selectTech}
          selectedTech={props.selectedTech}
        />
        <DownCaret
          onClick={() => {
            props.toggleDescription();
          }}
          descriptionOpen={props.descriptionOpen}
          src={downCaret}
          alt={`${props.title} description`}
        />
      </TechsLine>
      {props.descriptionOpen || isAnimating ? (
        <Description
          open={props.descriptionOpen}
          description={props.description}
          container={container}
          setIsAnimating={setIsAnimating}
        />
      ) : null}
    </div>
  );
};

const renderTitle = title => {
  if (title.length > 22) {
    const words = title.split(' ');
    return (
      <Fragment>
        <HigherTitle>{words.slice(0, words.length - 1).join(' ')}</HigherTitle>
        <Title>{words[words.length - 1]}</Title>
      </Fragment>
    );
  } else {
    return <Title>{title}</Title>;
  }
};

const Concept = props => {
  const [descriptionOpen, setDescriptionOpen] = useState(false);
  const [displayHerokuBanner, setHerokuDisplayBannerOpen] = useState(false);
  const [removeFilter, setRemoveFilter] = useState(false);

  const {
    title,
    full_name,
    description,
    languages,
    github_url,
    author_url,
    slug,
    is_heroku,
  } = props.concept;

  return (
    <ConceptContainer open={descriptionOpen} id={slug}>
      <a
        onClick={() => setHerokuDisplayBannerOpen(true)}
        href={props.concept.hrcpt_url}
        onMouseEnter={() => setRemoveFilter(true)}
        onMouseLeave={() => setRemoveFilter(false)}
      >
        <Screenshot
          coverImage={props.concept.cover_image || props.concept.screenshot_url}
          screenshotPath={props.concept.screenshot_url}
        />
        {!removeFilter && <ImgFilter />}
        {is_heroku && (
          <HerokuBanner open={displayHerokuBanner}>
            <HerokuContainer>
              <img src={herokuLogo} alt="Heroku Logo" />
              <div>
                We’re waking the Heroku dyno
                <br />
                Please be patient for ~30s
              </div>
              <HerokuSpinner>
                <HerokuSpinnerMiddle />
              </HerokuSpinner>
            </HerokuContainer>
          </HerokuBanner>
        )}
        {renderTitle(title)}
      </a>
      <InfoArea
        author={full_name}
        techs={languages}
        githubUrl={github_url}
        description={description}
        authorUrl={author_url}
        toggleDescription={() => {
          setDescriptionOpen(!descriptionOpen);
        }}
        descriptionOpen={descriptionOpen}
        selectTech={props.selectTech}
        selectedTech={props.selectedTech}
        title={title}
      />
    </ConceptContainer>
  );
};

class App extends Component {
  constructor(props) {
    super(props);
    this.state = { selectedTech: '' };
  }

  renderConcepts(concepts, selectTech, selectedTech) {
    return reverse(sortBy(concepts, concept => Date.parse(concept.created_at)))
      .filter(
        concept => !selectedTech || concept.languages.includes(selectedTech)
      )
      .map(concept => (
        <Concept
          key={concept.title}
          concept={concept}
          selectTech={selectTech}
          selectedTech={selectedTech}
        />
      ));
  }

  render() {
    const { concepts } = this.props;

    return (
      <ApplicationContainer>
        <Header>
          <a href="https://hashrocket.com">
            <HashrocketLogo>
              <img src={hashrocketHeader} alt="hashrocket logo" />
            </HashrocketLogo>
          </a>
          <a href="/">
            <ConceptsLogo>
              <img src={conceptsHeader} alt="concepts logo" />
            </ConceptsLogo>
          </a>
          <Tagline>A Gallery For Our Side Projects</Tagline>
        </Header>
        <ConceptsContainer>
          {this.renderConcepts(
            concepts,
            tech =>
              this.setState({
                selectedTech: this.state.selectedTech === tech ? '' : tech,
              }),
            this.state.selectedTech
          )}
        </ConceptsContainer>
      </ApplicationContainer>
    );
  }
}

export default App;
