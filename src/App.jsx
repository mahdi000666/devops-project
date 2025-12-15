import { useState } from 'react';
import './index.css';

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="container">
      <h1>DevOps CI/CD Project</h1>
      <p>ISG Sousse - 3 LIG</p>
      <div className="card">
        <button onClick={() => setCount(c => c + 1)}>
          Count: {count}
        </button>
      </div>
      <p className="info">
        Jenkins + Docker + Git Pipeline Demo
      </p>
    </div>
  );
}

export default App;