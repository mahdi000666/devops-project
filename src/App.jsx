import { useState } from 'react';
import './index.css';

function App() {
  const [count, setCount] = useState(0);

  const handleReset = () => {
    setCount(0);
  };

  return (
    <div className="container">
      <h1>DevOps CI/CD Project</h1>
      <p>ISG Sousse - 3 LIG</p>
      <div className="card">
        <button onClick={() => setCount(c => c + 1)}>
          Count: {count}
        </button>
        <button 
          onClick={handleReset}
          className="reset-btn"
          disabled={count === 0}
        >
          Reset
        </button>
      </div>
      <p className="info">
        Jenkins + Docker + Git Pipeline Demo
      </p>
    </div>
  );
}

export default App;