"use client";

import React from "react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Area, AreaChart } from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatDate } from "@/lib/utils";

interface SubmissionLineChartProps {
  data: { date: string; count: number }[];
}

export function SubmissionLineChart({ data }: SubmissionLineChartProps) {
  // Format dates for display
  const formattedData = data.map(item => ({
    ...item,
    displayDate: formatDate(item.date, "dd/MM"),
  }));

  return (
    <Card className="col-span-1 lg:col-span-2">
      <CardHeader>
        <CardTitle className="text-lg">Số lượng hồ sơ nộp trong 30 ngày</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-[300px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart
              data={formattedData}
              margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
            >
              <defs>
                <linearGradient id="colorCount" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#1B3F8B" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#1B3F8B" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} />
              <XAxis 
                dataKey="displayDate" 
                tick={{ fontSize: 12 }} 
                tickMargin={10}
              />
              <YAxis allowDecimals={false} />
              <Tooltip 
                contentStyle={{ borderRadius: '8px', border: '1px solid #e2e8f0' }}
                labelStyle={{ fontWeight: 'bold', color: '#0f172a' }}
              />
              <Area 
                type="monotone" 
                dataKey="count" 
                stroke="#1B3F8B" 
                strokeWidth={3}
                fillOpacity={1} 
                fill="url(#colorCount)" 
                activeDot={{ r: 6, fill: '#1B3F8B', stroke: '#fff', strokeWidth: 2 }}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}
