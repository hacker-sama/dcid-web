"use client";

import React from "react";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { STATUS_CONFIG } from "@/constants/application-status";

interface StatusBarChartProps {
  data: { status: string; count: number }[];
}

export function StatusBarChart({ data }: StatusBarChartProps) {
  // Format data for Recharts
  const formattedData = data.map(item => {
    const statusKey = item.status as keyof typeof STATUS_CONFIG;
    const config = STATUS_CONFIG[statusKey];
    
    // Extract hex color from class or use fallback
    let fill = "#8884d8"; // default
    if (statusKey === "APPROVED") fill = "#16a34a";
    else if (statusKey === "REJECTED") fill = "#dc2626";
    else if (statusKey === "IN_REVIEW") fill = "#d97706";
    else if (statusKey === "SUBMITTED") fill = "#1b3f8b";
    
    return {
      name: config?.label || item.status,
      count: item.count,
      fill,
    };
  });

  return (
    <Card className="col-span-1">
      <CardHeader>
        <CardTitle className="text-lg">Trạng thái hồ sơ</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-[300px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={formattedData}
              margin={{ top: 20, right: 30, left: 0, bottom: 5 }}
            >
              <CartesianGrid strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="name" tick={{ fontSize: 12 }} />
              <YAxis allowDecimals={false} />
              <Tooltip 
                cursor={{ fill: 'transparent' }}
                contentStyle={{ borderRadius: '8px', border: '1px solid #e2e8f0' }}
              />
              <Bar dataKey="count" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}
