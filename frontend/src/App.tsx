import React, { useState, useEffect, useCallback } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

import { Button } from "@/components/ui/button"
import { Slider } from "@/components/ui/slider"
import { Label } from "@/components/ui/label"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

// Types
interface ComponentProps {
  id?: string;
  type: string;
  props: any;
  children?: ComponentProps[];
}

interface RenderEvent {
  type: 'render';
  components: ComponentProps[];
}

interface UserEvent {
  type: 'event';
  id: string;
  event: string;
  value: any;
}

// Simple components
const Markdown = ({ content }: { content: string }) => (
  <div className="prose prose-slate max-w-none mb-4 dark:prose-invert">
    <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
  </div>
);

const NightingaleButton = ({ id, label, onEvent }: { id: string, label: string, value: boolean, onEvent: (id: string, type: string, val: any) => void }) => (
  <div className="mb-4">
    <Button
      onClick={() => onEvent(id, 'click', true)}
    >
      {label}
    </Button>
  </div>
);

const NightingaleSlider = ({ id, label, min, max, value, step, onEvent }: { id: string, label: string, min: number, max: number, value: number, step: number, onEvent: (id: string, type: string, val: any) => void }) => (
  <div className="mb-4 space-y-2">
    <Label>{label} ({value})</Label>
    <Slider
      min={min}
      max={max}
      step={step}
      value={[value]}
      onValueChange={(vals: number[]) => onEvent(id, 'change', vals[0])}
    />
  </div>
);

const NightingaleDataFrame = ({ data }: { data: any[] }) => {
  if (!data || data.length === 0) return null;
  const headers = Object.keys(data[0]);
  return (
    <div className="rounded-md border mb-4">
      <Table>
        <TableHeader>
          <TableRow>
            {headers.map(h => (
              <TableHead key={h}>{h}</TableHead>
            ))}
          </TableRow>
        </TableHeader>
        <TableBody>
          {data.map((row, i) => (
            <TableRow key={i}>
              {headers.map(h => (
                <TableCell key={h}>{JSON.stringify(row[h])}</TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
};

const Title = ({ text }: { text: string }) => (
  <h1 className="text-3xl font-bold tracking-tight mb-6">{text}</h1>
);

const ComponentRenderer = ({ component, onEvent }: { component: ComponentProps, onEvent: (id: string, type: string, val: any) => void }) => {
  const { type, props, id, children } = component;

  const renderChildren = () => (
    children ? children.map((child, i) => (
      <ComponentRenderer key={i} component={child} onEvent={onEvent} />
    )) : null
  );

  switch (type) {
    case 'title': return <Title {...props} />;
    case 'markdown': return <Markdown {...props} />;
    case 'button': return <NightingaleButton id={id!} {...props} onEvent={onEvent} />;
    case 'slider': return <NightingaleSlider id={id!} {...props} onEvent={onEvent} />;
    case 'dataframe': return <NightingaleDataFrame {...props} />;
    case 'sidebar':
      return (
        <div className="bg-muted/40 border-r min-h-screen w-64 fixed left-0 top-0 overflow-y-auto p-4">
          {renderChildren()}
        </div>
      );
    default:
      return <div className="text-destructive">Unknown component: {type}</div>;
  }
};

function App() {
  const [components, setComponents] = useState<ComponentProps[]>([]);
  const [connected, setConnected] = useState(false);
  const [ws, setWs] = useState<WebSocket | null>(null);

  useEffect(() => {
    const socket = new WebSocket('ws://localhost:4567/ws');

    socket.onopen = () => {
      console.log('Connected to server');
      setConnected(true);
    };

    socket.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type === 'render') {
        setComponents(data.components);
      }
    };

    socket.onclose = () => {
      console.log('Disconnected');
      setConnected(false);
    };

    setWs(socket);

    return () => {
      socket.close();
    };
  }, []);

  const handleEvent = useCallback((id: string, eventType: string, value: any) => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'event',
        id,
        event: eventType,
        value
      }));
    }
  }, [ws]);

  // Separate sidebar and main content
  const sidebarComponents = components.filter(c => c.type === 'sidebar');
  const mainComponents = components.filter(c => c.type !== 'sidebar');

  return (
    <div className="min-h-screen bg-background text-foreground font-sans antialiased">
      {sidebarComponents.map((c, i) => (
        <ComponentRenderer key={`sidebar-${i}`} component={c} onEvent={handleEvent} />
      ))}

      <div className={`p-8 max-w-4xl mx-auto ${sidebarComponents.length > 0 ? 'ml-64' : ''}`}>
        {!connected && (
          <div className="bg-yellow-100 border-l-4 border-yellow-500 text-yellow-700 p-4 mb-4">
            <p>Connecting to server...</p>
          </div>
        )}

        {mainComponents.map((c, i) => (
          <ComponentRenderer key={i} component={c} onEvent={handleEvent} />
        ))}
      </div>
    </div>
  );
}

export default App;
