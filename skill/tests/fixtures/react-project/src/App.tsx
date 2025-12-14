import React from 'react';

interface AppProps {
  title: string;
}

export const App: React.FC<AppProps> = ({ title }) => {
  return <h1>{title}</h1>;
};
